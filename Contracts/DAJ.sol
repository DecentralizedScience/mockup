pragma solidity^0.4.0;

//DAJ contract template (Decentralized Autonomous Journal)
contract DAJ{

    //Structs
    struct Paper{
        // IPFS Address of the file
        // i.e. QmbFMke1KXqnYyBBWxB74N4c5SBnJMVAiMNRcGu6x1AwQH
        string ipfsAddress;

        // Ethereum's address of the author
        address[] authors;

        // (Optional) Bitcoin address for donations
        string btcAddress;

        // Check if the paper is acepted
        bool acepted;

        //Reviewers asigned to the Paper
        address[] reviewers;

        Review[] reviews;

    }

    struct Review{
        //Reviews
        address reviewer;
        string reviewIpfsAddress;
        uint acceptance;
    }

    //Variables
    mapping(uint => Paper) public papers;
    mapping(string => uint) ipfsPaperMap;
    uint numPapers;

    address owner;

    uint[] pendingPapers;

    //Modifiers
    modifier onlyReviewerAssigned(string _ipfsAddress){
        bool canReview = false;
        address[] storage addresses = papers[ipfsPaperMap[_ipfsAddress]].reviewers;
        for(uint i = 0 ; i < 3 ; i++){
            if ( addresses[i] == msg.sender ){
                canReview = true;
            }
        }
        require(canReview);
        _;
    }

    //Events
    event ReviewersAssigned(
        address[] _reviewerAddresses,
        uint _paperId,
        string _ipfsAddress);
    event PaperSent(
        address _from,
        address[] _authors,
        uint _paperId,
        string _ipfsAddress);
    event ReviewSent(
        address _reviewerAddress,
        uint _aceptance,
        string _paperIpfsAddress,
        string _reviewIpfsAddress);

    //Functions
    function DAJ() public{
        numPapers = 0;
        owner = msg.sender;
    }

    function getPaper(uint numPaper)
    constant
    public
    returns (
        string ipfsAddres,
        string btcAddress,
        address[] authors,
        address[] reviewers
        ){
        return (
            papers[numPaper].ipfsAddress,
            papers[numPaper].btcAddress,
            papers[numPaper].authors,
            papers[numPaper].reviewers
        );
    }

    function sendPaper(
        string _ipfsAddress,
        string _btcAddress,
        address[] _authors
        )
        public{
        papers[numPapers].ipfsAddress = _ipfsAddress;
        papers[numPapers].authors = _authors;
        ipfsPaperMap[_ipfsAddress] = numPapers;
        PaperSent(msg.sender,_authors,numPapers,_ipfsAddress);
        numPapers++;
    }

    function assignReviewers(uint _paperId, address[] _reviewers)
    public
    //only editors TODO modifier
    {
        papers[_paperId].reviewers = _reviewers;
        ReviewersAssigned(_reviewers,_paperId,papers[_paperId].ipfsAddress);
    }

    function sendReview(string _ipfsAddress, uint _acceptance, string _reviewIpfsAddress)
    public
    onlyReviewerAssigned(_ipfsAddress){
        uint paperId = ipfsPaperMap[_ipfsAddress];
        Review storage newReview;
        newReview.reviewer = msg.sender;
        newReview.acceptance = _acceptance;
        newReview.reviewIpfsAddress = _reviewIpfsAddress;
        papers[paperId].reviews.push(newReview);
        ReviewSent(msg.sender, _acceptance, _ipfsAddress, _reviewIpfsAddress);
        //TODO check if the paper is accepted
    }

    //TODO function to rate reviews
}
