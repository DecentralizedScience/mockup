pragma solidity^0.4.0;

//DAJ contract template (Decentralized Autonomous Journal)
contract DAJ{

    //Structs
    struct Paper{
        // IPFS Address of the file
        // i.e. QmbFMke1KXqnYyBBWxB74N4c5SBnJMVAiMNRcGu6x1AwQH
        string ipfsPaperAddress;

        // Ethereum's address of the author
        address[] authors;

        // (Optional) Bitcoin address for donations
        string btcAddress;

        // Check if the paper is acepted
        bool published;

        //Reviewers asigned to the Paper
        address[] reviewers;

        //Hashes of the reviews
        bytes32[] reviewHashes;
    }

    struct Review{
        //Reviews
        address reviewer;
        string ipfsPaperAddress;
        string ipfsReviewAddress;
        /*
        0 - Reject
        1 - Major Revision
        2 - Minor Revision
        3 - Accept
        */
        uint acceptance;
    }

    struct Rating{
        address rater;
        address reviewer;
        bytes32 reviewHash;
        uint numRating;
    }

    /**
    Variables
    **/

    //Mapping for editors - level of privilege
    mapping(address => uint) editors;

    //Mapping structure for papers
    mapping(uint => Paper) public idPaperMap;
    mapping(string => uint) ipfsPaperMap;
    uint numPapers;

    //Owner of the contract
    address owner;

    //Pending papers waiting for reviews
    uint[] pendingPapers;

    //Reviews mapping of the pending papers
    mapping(bytes32 => Review) reviewHashMapping;

    //Rating mapping of the reviews
    mapping(bytes32 => Rating) reviewsRating;

    /*
    Modifiers
    */
    modifier onlyReviewerAssigned(string _ipfsPaperAddress){
        bool canReview = false;
        address[] storage addresses = idPaperMap[ipfsPaperMap[_ipfsPaperAddress]].reviewers;
        //TODO modify num-reviwer
        for(uint i = 0 ; i < 3 ; i++){
            if ( addresses[i] == msg.sender ){
                canReview = true;
            }
        }
        require(canReview);
        _;
    }

    //Level 1 needed
    modifier onlyEditors(){
        require(editors[msg.sender] > 0);
        _;
    }

    //Level 2 needed
    modifier onlyLevel2Editors(){
        require(editors[msg.sender] > 1);
        _;
    }

    //Events
    event ReviewersAssigned(
        address[] _reviewerAddresses,
        uint _paperId,
        string _ipfsPaperAddress);
    event PaperSent(
        address _from,
        address[] _authors,
        uint _paperId,
        string _ipfsPaperAddress);
    event PaperPublished(string _ipfsPaperAddress);
    event ReviewSent(
        address _reviewerAddress,
        string _ipfsPaperAddress,
        string _ipfsReviewAddress,
        uint _aceptance,
        bytes32 reviewHash);
    event ReviewRated(
        address _from,
        address _toReviewer,
        string _ipfsPaperAddress,
        string _ipfsReviewAddress,
        uint _rating
        );

    /*
    Functions
    */

    function DAJ() public{
        numPapers = 0;
        owner = msg.sender;
    }

    function getPaper(uint paperId)
    constant
    public
    returns (
        string ipfsPaperAddress,
        string btcAddress,
        address[] authors,
        address[] reviewers
        ){
        return (
            idPaperMap[paperId].ipfsPaperAddress,
            idPaperMap[paperId].btcAddress,
            idPaperMap[paperId].authors,
            idPaperMap[paperId].reviewers
        );
    }

    function sendPaper(
        string _ipfsPaperAddress,
        string _btcAddress,
        address[] _authors
        )
        public{
        idPaperMap[numPapers].ipfsPaperAddress = _ipfsPaperAddress;
        idPaperMap[numPapers].btcAddress = _btcAddress;
        idPaperMap[numPapers].authors = _authors;
        ipfsPaperMap[_ipfsPaperAddress] = numPapers;
        PaperSent(msg.sender,_authors,numPapers,_ipfsPaperAddress);
        numPapers++;
    }

    function assignReviewers(string _ipfsPaperAddress, address[] _reviewers)
    public
    onlyEditors()
    {
        uint paperId = ipfsPaperMap[_ipfsPaperAddress];
        idPaperMap[paperId].reviewers = _reviewers;
        ReviewersAssigned(_reviewers,paperId,idPaperMap[paperId].ipfsPaperAddress);
    }

    function sendReview(
      string _ipfsPaperAddress,
      uint _acceptance,
      string _ipfsReviewAddress
      )
    public
    onlyReviewerAssigned( _ipfsPaperAddress ){
        uint paperId = ipfsPaperMap[_ipfsPaperAddress];
        Review memory newReview = Review(
          msg.sender,
          _ipfsPaperAddress,
          _ipfsReviewAddress,
          _acceptance
        );
        bytes32 reviewHash = keccak256(msg.sender, _ipfsReviewAddress);
        reviewHashMapping[reviewHash] = newReview;
        idPaperMap[paperId].reviewHashes.push(reviewHash);
        ReviewSent(
          msg.sender,
          _ipfsPaperAddress,
          _ipfsReviewAddress,
          _acceptance,
          reviewHash
          );
        //TODO check if the paper is accepted
        checkAcceptance(paperId);
    }

    function checkAcceptance(uint paperId)
    private{

        //Custom acceptance metrics
        bytes32[] memory hashes = idPaperMap[paperId].reviewHashes;
        for(uint i = 0 ; i < hashes.length ; i++){
            if(reviewHashMapping[hashes[i]].acceptance < 2){
                return;
            }
        }
        idPaperMap[paperId].published = true;
        PaperPublished(idPaperMap[paperId].ipfsPaperAddress);
    }

    function rateReview(bytes32 _reviewHash, uint _rateReview)
    public{
        Review memory review = reviewHashMapping[_reviewHash];
        bytes32 rateOfReviewHash = keccak256(
          review.ipfsPaperAddress,
          review.reviewer,
          msg.sender
        );
        Rating memory newRating = Rating(
            msg.sender,
            review.reviewer,
            _reviewHash,
            _rateReview
            );
        reviewsRating[rateOfReviewHash] = newRating;
        ReviewRated(
            msg.sender,
            review.reviewer,
            review.ipfsPaperAddress,
            review.ipfsReviewAddress,
            _rateReview
        );
    }
}
