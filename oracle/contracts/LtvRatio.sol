pragma solidity 0.4.24;

import 'chainlink/contracts/ChainlinkClient.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract LtvRatio is ChainlinkClient, Ownable {
    uint256 private constant ORACLE_PAYMENT = 1 * LINK;

    address internal oracle;
    string internal jobId;

    event LtvRatio(
        bytes32 indexed requestId,
        uint256 timestamp,
        int64[4] ratios
    );

    constructor(address _oracle, string _jobId) public Ownable() {
        setPublicChainlinkToken();
        oracle = _oracle;
        jobId = _jobId;
    }

    function requestLtvRatio(string _score) public {
        Chainlink.Request memory req = buildChainlinkRequest(
            stringToBytes32(jobId),
            this,
            this.fulfillRatios.selector
        );
        req.add('score', _score);
        req.add('path', 'ratios');
        sendChainlinkRequestTo(oracle, req, ORACLE_PAYMENT);
    }

    function fulfillRatios(bytes32 _requestId, bytes32 _ratios)
        public
        recordChainlinkFulfillment(_requestId)
    {


        emit LtvRatio(_requestId, block.timestamp, unpack(_ratios));
    }

    function unpack (bytes32 x) internal returns (int64[4] ratios) {
        return [
            int64 (bytes8 (x)),
            int64 (bytes8 (x << 64)),
            int64 (bytes8 (x << 128)),
            int64 (bytes8 (x << 192))
        ];
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
