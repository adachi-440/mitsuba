// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IOFTCore.sol";
import "./interfaces/IReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ICrossChainRouter.sol";
import "./util/BytesLib.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract OFTCore is ERC165, IOFTCore, IReceiver, Ownable {
    using BytesLib for bytes;

    uint public constant NO_EXTRA_GAS = 0;

    // packet type
    uint16 public constant PT_SEND = 0;

    bool public useCustomAdapterParams;

    ILayerZeroEndpoint public immutable lzEndpoint;
    ICrossChainRouter public immutable router;

    constructor(address _lzEndpoint, address _router) {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        router = ICrossChainRouter(_router);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IOFTCore).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function estimateSendFee(
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) public view virtual override returns (uint nativeFee, uint zroFee) {
        // mock the payload for sendFrom()
        bytes memory payload = abi.encode(
            _toAddress,
            abi.encode(PT_SEND, _toAddress, _amount)
        );
        return
            lzEndpoint.estimateFees(
                _dstChainId,
                address(this),
                payload,
                _useZro,
                bytes("")
            );
    }

    function sendFrom(
        address _from,
        uint32 _dstChainId,
        address _toAddress,
        uint _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) public payable virtual {
        _send(
            _from,
            _dstChainId,
            _toAddress,
            _amount,
            _refundAddress,
            _zroPaymentAddress
        );
    }

    function setUseCustomAdapterParams(
        bool _useCustomAdapterParams
    ) public virtual onlyOwner {
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    function receiveMessage(
        bytes32 messageId,
        uint32 originChainId,
        address originSender,
        bytes memory callData
    ) external {
        uint16 packetType;
        assembly {
            packetType := mload(add(callData, 32))
        }

        if (packetType == PT_SEND) {
            _sendAck(originChainId, originSender, callData);
        } else {
            revert("OFTCore: unknown packet type");
        }
    }

    function _send(
        address _from,
        uint32 _dstChainId,
        address _toAddress,
        uint _amount,
        address payable _refundAddress,
        address _zroPaymentAddress
    ) internal virtual {
        // _checkAdapterParams(_dstChainId, PT_SEND, _adapterParams, NO_EXTRA_GAS);

        uint amount = _debitFrom(_from, _dstChainId, _toAddress, _amount);

        bytes memory lzPayload = abi.encode(PT_SEND, _toAddress, amount);
        router.sendMessage{value: msg.value}(
            3,
            _dstChainId,
            msg.value,
            _toAddress,
            lzPayload
        );

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function _sendAck(
        uint32 _srcChainId,
        address,
        bytes memory _payload
    ) internal virtual {
        (, address to, uint amount) = abi.decode(
            _payload,
            (uint16, address, uint)
        );

        amount = _creditTo(_srcChainId, to, amount);
        emit ReceiveFromChain(_srcChainId, to, amount);
    }

    // function _checkAdapterParams(
    //     uint16 _dstChainId,
    //     uint16 _pkType,
    //     bytes memory _adapterParams,
    //     uint _extraGas
    // ) internal virtual {
    //     if (useCustomAdapterParams) {
    //         _checkGasLimit(_dstChainId, _pkType, _adapterParams, _extraGas);
    //     } else {
    //         require(
    //             _adapterParams.length == 0,
    //             "OFTCore: _adapterParams must be empty."
    //         );
    //     }
    // }

    function _debitFrom(
        address _from,
        uint32 _dstChainId,
        address _toAddress,
        uint _amount
    ) internal virtual returns (uint);

    function _creditTo(
        uint32 _srcChainId,
        address _toAddress,
        uint _amount
    ) internal virtual returns (uint);
}
