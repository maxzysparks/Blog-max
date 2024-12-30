// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedBlog is ReentrancyGuard, Pausable, Ownable {
    // Constants
    uint256 private constant MAX_TITLE_LENGTH = 200;
    uint256 private constant MAX_CONTENT_LENGTH = 5000;
    uint256 private constant MAX_BIO_LENGTH = 1000;
    uint256 private constant MAX_URL_LENGTH = 500;
    uint256 private constant MAX_SOCIAL_LINKS = 5;
    uint256 private constant MAX_TAGS = 10;
    uint256 private constant POSTS_PER_PAGE = 10;

    struct BlogPost {
        uint256 id;
        address author;
        string title;
        string content;
        uint256 likes;
        string category;
        string[] tags;
        bool isDeleted;
        uint256 timestamp;
        uint256 lastModified;
    }

    struct UserProfile {
        string bio;
        string profilePictureUrl;
        string[] socialMediaLinks;
        bool isActive;
        uint256 lastUpdated;
    }

    struct Subscriber {
        address subscriberAddress;
        bool subscribed;
        uint256 subscribedAt;
    }

    // State variables
    uint256 public totalPosts;
    uint256 public activePosts;
    
    mapping(uint256 => BlogPost) public blogPosts;
    mapping(address => UserProfile) public userProfiles;
    mapping(address => Subscriber) public subscribers;
    mapping(address => bool) public authorizedUsers;
    mapping(uint256 => mapping(address => bool)) public postLikes;
    mapping(address => uint256[]) public userPosts;
    
    // Events
    event PostCreated(uint256 indexed id, address indexed author, string title, string category, uint256 timestamp);
    event PostUpdated(uint256 indexed id, address indexed author, string title, uint256 timestamp);
    event PostDeleted(uint256 indexed id, address indexed author, uint256 timestamp);
    event PostLiked(uint256 indexed id, address indexed liker, uint256 totalLikes);
    event PostUnliked(uint256 indexed id, address indexed unliker, uint256 totalLikes);
    event UserProfileUpdated(address indexed user, uint256 timestamp);
    event SubscriberAdded(address indexed subscriber, uint256 timestamp);
    event SubscriberRemoved(address indexed subscriber, uint256 timestamp);
    event UserAuthorized(address indexed user, uint256 timestamp);
    event UserDeauthorized(address indexed user, uint256 timestamp);

    // Modifiers
    modifier onlyAuthorized() {
        require(authorizedUsers[msg.sender], "Unauthorized user");
        _;
    }

    modifier onlyPostAuthor(uint256 _postId) {
        require(blogPosts[_postId].author == msg.sender, "Only author can modify");
        _;
    }

    modifier validPostId(uint256 _postId) {
        require(_postId > 0 && _postId <= totalPosts, "Invalid post ID");
        require(!blogPosts[_postId].isDeleted, "Post has been deleted");
        _;
    }

    modifier activeUser() {
        require(userProfiles[msg.sender].isActive, "User profile not active");
        _;
    }

    // Constructor
    constructor() Ownable(msg.sender) {
        totalPosts = 0;
        activePosts = 0;
    }

    // Admin functions
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function authorizeUser(address _user) public onlyOwner {
        require(!authorizedUsers[_user], "User already authorized");
        authorizedUsers[_user] = true;
        emit UserAuthorized(_user, block.timestamp);
    }

    function deauthorizeUser(address _user) public onlyOwner {
        require(authorizedUsers[_user], "User not authorized");
        authorizedUsers[_user] = false;
        emit UserDeauthorized(_user, block.timestamp);
    }

    // User profile functions
    function createUser(
        string memory _bio,
        string memory _profilePictureUrl
    ) public whenNotPaused {
        require(!userProfiles[msg.sender].isActive, "User already exists");
        require(bytes(_bio).length <= MAX_BIO_LENGTH, "Bio too long");
        require(bytes(_profilePictureUrl).length <= MAX_URL_LENGTH, "URL too long");

        UserProfile storage profile = userProfiles[msg.sender];
        profile.bio = _bio;
        profile.profilePictureUrl = _profilePictureUrl;
        profile.isActive = true;
        profile.lastUpdated = block.timestamp;

        authorizedUsers[msg.sender] = true;
        emit UserAuthorized(msg.sender, block.timestamp);
    }

    function updateUserProfile(
        string memory _bio,
        string memory _profilePictureUrl,
        string[] memory _socialMediaLinks
    ) public whenNotPaused onlyAuthorized activeUser {
        require(bytes(_bio).length <= MAX_BIO_LENGTH, "Bio too long");
        require(bytes(_profilePictureUrl).length <= MAX_URL_LENGTH, "URL too long");
        require(_socialMediaLinks.length <= MAX_SOCIAL_LINKS, "Too many social links");

        UserProfile storage profile = userProfiles[msg.sender];
        profile.bio = _bio;
        profile.profilePictureUrl = _profilePictureUrl;
        profile.socialMediaLinks = _socialMediaLinks;
        profile.lastUpdated = block.timestamp;

        emit UserProfileUpdated(msg.sender, block.timestamp);
    }

    // Blog post functions
    function createPost(
        string memory _title,
        string memory _content,
        string memory _category,
        string[] memory _tags
    ) public whenNotPaused onlyAuthorized activeUser nonReentrant {
        require(bytes(_title).length > 0 && bytes(_title).length <= MAX_TITLE_LENGTH, "Invalid title length");
        require(bytes(_content).length > 0 && bytes(_content).length <= MAX_CONTENT_LENGTH, "Invalid content length");
        require(_tags.length <= MAX_TAGS, "Too many tags");

        totalPosts++;
        activePosts++;

        BlogPost storage post = blogPosts[totalPosts];
        post.id = totalPosts;
        post.author = msg.sender;
        post.title = _title;
        post.content = _content;
        post.category = _category;
        post.tags = _tags;
        post.timestamp = block.timestamp;
        post.lastModified = block.timestamp;

        userPosts[msg.sender].push(totalPosts);

        emit PostCreated(totalPosts, msg.sender, _title, _category, block.timestamp);
    }

    function updatePost(
        uint256 _postId,
        string memory _title,
        string memory _content,
        string memory _category,
        string[] memory _tags
    ) public whenNotPaused onlyAuthorized activeUser validPostId(_postId) onlyPostAuthor(_postId) nonReentrant {
        require(bytes(_title).length > 0 && bytes(_title).length <= MAX_TITLE_LENGTH, "Invalid title length");
        require(bytes(_content).length > 0 && bytes(_content).length <= MAX_CONTENT_LENGTH, "Invalid content length");
        require(_tags.length <= MAX_TAGS, "Too many tags");

        BlogPost storage post = blogPosts[_postId];
        post.title = _title;
        post.content = _content;
        post.category = _category;
        post.tags = _tags;
        post.lastModified = block.timestamp;

        emit PostUpdated(_postId, msg.sender, _title, block.timestamp);
    }

    function deletePost(uint256 _postId) 
        public 
        whenNotPaused 
        onlyAuthorized 
        activeUser 
        validPostId(_postId) 
        onlyPostAuthor(_postId) 
        nonReentrant 
    {
        BlogPost storage post = blogPosts[_postId];
        post.isDeleted = true;
        activePosts--;

        emit PostDeleted(_postId, msg.sender, block.timestamp);
    }

    function likePost(uint256 _postId) 
        public 
        whenNotPaused 
        activeUser 
        validPostId(_postId) 
        nonReentrant 
    {
        require(!postLikes[_postId][msg.sender], "Already liked this post");
        
        BlogPost storage post = blogPosts[_postId];
        post.likes++;
        postLikes[_postId][msg.sender] = true;
        
        emit PostLiked(_postId, msg.sender, post.likes);
    }

    function unlikePost(uint256 _postId) 
        public 
        whenNotPaused 
        activeUser 
        validPostId(_postId) 
        nonReentrant 
    {
        require(postLikes[_postId][msg.sender], "Haven't liked this post");
        
        BlogPost storage post = blogPosts[_postId];
        post.likes--;
        postLikes[_postId][msg.sender] = false;
        
        emit PostUnliked(_postId, msg.sender, post.likes);
    }

    // Query functions
    function getPost(uint256 _postId)
        public
        view
        validPostId(_postId)
        returns (
            uint256 id,
            address author,
            string memory title,
            string memory content,
            uint256 likes,
            string memory category,
            string[] memory tags,
            uint256 timestamp,
            uint256 lastModified
        )
    {
        BlogPost storage post = blogPosts[_postId];
        return (
            post.id,
            post.author,
            post.title,
            post.content,
            post.likes,
            post.category,
            post.tags,
            post.timestamp,
            post.lastModified
        );
    }

    function getPostsByPage(uint256 _page) 
        public 
        view 
        returns (uint256[] memory) 
    {
        require(_page > 0, "Invalid page number");
        
        uint256 startIndex = (_page - 1) * POSTS_PER_PAGE + 1;
        uint256 endIndex = min(startIndex + POSTS_PER_PAGE - 1, totalPosts);
        
        uint256[] memory pageIds = new uint256[](endIndex - startIndex + 1);
        uint256 count = 0;
        
        for (uint256 i = startIndex; i <= endIndex; i++) {
            if (!blogPosts[i].isDeleted) {
                pageIds[count] = i;
                count++;
            }
        }
        
        return truncateArray(pageIds, count);
    }

    function getPostsByAuthor(address _author) 
        public 
        view 
        returns (uint256[] memory) 
    {
        return userPosts[_author];
    }

    function getPostsByCategory(string memory _category)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= totalPosts; i++) {
            if (!blogPosts[i].isDeleted && 
                keccak256(bytes(blogPosts[i].category)) == keccak256(bytes(_category))) {
                count++;
            }
        }
        
        uint256[] memory categoryPosts = new uint256[](count);
        count = 0;
        
        for (uint256 i = 1; i <= totalPosts; i++) {
            if (!blogPosts[i].isDeleted && 
                keccak256(bytes(blogPosts[i].category)) == keccak256(bytes(_category))) {
                categoryPosts[count] = i;
                count++;
            }
        }
        
        return categoryPosts;
    }

    // Subscription functions
    function subscribe() public whenNotPaused activeUser nonReentrant {
        require(!subscribers[msg.sender].subscribed, "Already subscribed");

        subscribers[msg.sender] = Subscriber(msg.sender, true, block.timestamp);
        emit SubscriberAdded(msg.sender, block.timestamp);
    }

    function unsubscribe() public whenNotPaused activeUser nonReentrant {
        require(subscribers[msg.sender].subscribed, "Not subscribed");

        delete subscribers[msg.sender];
        emit SubscriberRemoved(msg.sender, block.timestamp);
    }

    // Utility functions
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function truncateArray(uint256[] memory arr, uint256 newSize) 
        private 
        pure 
        returns (uint256[] memory) 
    {
        uint256[] memory truncated = new uint256[](newSize);
        for (uint256 i = 0; i < newSize; i++) {
            truncated[i] = arr[i];
        }
        return truncated;
    }
}