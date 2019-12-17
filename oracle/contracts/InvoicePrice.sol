pragma solidity 0.4.24;

import 'chainlink/contracts/ChainlinkClient.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract InvoicePrice is ChainlinkClient, Ownable {
    uint256 private constant ORACLE_PAYMENT = 1 * LINK;

    address internal oracle;
    string internal jobId;

    event InvoicePrice(
        bytes32 indexed requestId,
        uint256 timestamp,
        uint256 price
    );

    constructor(address _oracle, string _jobId) public Ownable() {
        setPublicChainlinkToken();
        oracle = _oracle;
        jobId = _jobId;
    }

    function requestInvoiceRate(string _days) public {
        Chainlink.Request memory req = buildChainlinkRequest(
            stringToBytes32(jobId),
            this,
            this.fulfillRate.selector
        );
        req.add('days', _days);
        req.add('path', 'rate');
        sendChainlinkRequestTo(oracle, req, ORACLE_PAYMENT);
    }

    function fulfillRate(bytes32 _requestId, uint256 _rate)
        public
        recordChainlinkFulfillment(_requestId)
    {
        emit InvoicePrice(_requestId, block.timestamp, _rate);
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            'Unable to transfer'
        );
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner {
        cancelChainlinkRequest(
            _requestId,
            _payment,
            _callbackFunctionId,
            _expiration
        );
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

}
