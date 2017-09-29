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
        bool published;

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

    struct Rating{
        address rater;
        address reviewer;
        uint numRating;
    }


    //Variables
    mapping(uint => Paper) public papers;
    mapping(string => uint) ipfsPaperMap;
    uint numPapers;

    address owner;

    uint[] pendingPapers;

    mapping(bytes32 => Rating) reviewsRating;

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
    event ReviewRated(
        address _from,
        address _toReviewer,
        //string _reviewIpfsAddress,
        string _paperIpfsAddress,
        uint _rating
        );

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
        papers[numPapers].btcAddress = _btcAddress;
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

    function sendReview(
      string _ipfsAddress,
      uint _acceptance,
      string _reviewIpfsAddress
      )
    public
    onlyReviewerAssigned(_ipfsAddress){
        uint paperId = ipfsPaperMap[_ipfsAddress];
        Review memory newReview = Review(
          msg.sender,
          _reviewIpfsAddress,
          _acceptance
          );
        papers[paperId].reviews.push(newReview);
        ReviewSent(msg.sender, _acceptance, _ipfsAddress, _reviewIpfsAddress);
        //TODO check if the paper is accepted
        checkAcceptance(paperId);
    }

    function checkAcceptance(uint paperId)
    private{
        Review[] memory reviews = papers[paperId].reviews;
        for(uint i = 0 ; i < 3 ; i++){
            if(reviews[i].acceptance < 2){
                return;
            }
        }
        papers[paperId].published = true;
    }
    //TODO function to rate reviews

    function rateReview(
        string _ipfsAddress,
        address _reviewerAddress,
        uint _rateReview)
    public{
        bytes32 reviewHash = keccak256(_ipfsAddress, _reviewerAddress);
        Rating memory newRating = Rating(msg.sender, _reviewerAddress, _rateReview);
        reviewsRating[reviewHash] = newRating;
        ReviewRated(msg.sender,_reviewerAddress, _ipfsAddress, _rateReview);
    }
}
