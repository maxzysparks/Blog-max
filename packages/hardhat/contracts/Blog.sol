// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract DecentralizedBlog {
    struct BlogPost {
        uint256 id;
        address author;
        string title;
        string content;
        uint256 likes;
        string category;
        string[] tags;
    }

    struct UserProfile {
        string bio;
        string profilePictureUrl;
        string[] socialMediaLinks;
    }

    struct Subscriber {
        address subscriberAddress;
        bool subscribed;
    }

    uint256 public totalPosts;

    mapping(uint256 => BlogPost) public blogPosts;
    mapping(address => UserProfile) public userProfiles;

    mapping(address => Subscriber) public subscribers;
    mapping(address => bool) public authorizedUsers;

    event PostCreated(
        uint256 indexed id,
        address indexed author,
        string title,
        string content
    );

    event PostLiked(uint256 indexed id, address indexed liker);

    event SubscriberAdded(address indexed subscriber);

    event SubscriberRemoved(address indexed subscriber);

    modifier onlyAuthorized() {
        require(authorizedUsers[msg.sender], "Unauthorized user");
        _;
    }

    function createUser() public {
        authorizedUsers[msg.sender] = true;
    }

    function updateUserProfile(
        string memory _bio,
        string memory _profilePictureUrl,
        string[] memory _socialMediaLinks
    ) public {
        UserProfile storage profile = userProfiles[msg.sender];
        profile.bio = _bio;
        profile.profilePictureUrl = _profilePictureUrl;
        profile.socialMediaLinks = _socialMediaLinks;
    }

    function searchPostsByKeyword(string memory _keyword)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory matchingPosts = new uint256[](totalPosts);
        uint256 count = 0;

        for (uint256 i = 1; i <= totalPosts; i++) {
            BlogPost storage post = blogPosts[i];
            string memory content = string(
                abi.encodePacked(post.title, post.content)
            );

            if (containsKeyword(content, _keyword)) {
                matchingPosts[count] = i;
                count++;
            }
        }

        uint256[] memory results = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            results[i] = matchingPosts[i];
        }

        return results;
    }

    function containsKeyword(string memory _content, string memory _keyword)
        private
        pure
        returns (bool)
    {
        bytes memory contentBytes = bytes(_content);
        bytes memory keywordBytes = bytes(_keyword);

        uint256 contentLength = contentBytes.length;
        uint256 keywordLength = keywordBytes.length;

        for (uint256 i = 0; i <= contentLength - keywordLength; i++) {
            bool found = true;
            for (uint256 j = 0; j < keywordLength; j++) {
                if (contentBytes[i + j] != keywordBytes[j]) {
                    found = false;
                    break;
                }
            }

            if (found) {
                return true;
            }
        }

        return false;
    }

    function getPostsByCategory(string memory _category)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory categoryPosts = new uint256[](totalPosts);
        uint256 count = 0;

        for (uint256 i = 1; i <= totalPosts; i++) {
            if (
                keccak256(bytes(blogPosts[i].category)) ==
                keccak256(bytes(_category))
            ) {
                categoryPosts[count] = i;
                count++;
            }
        }

        return categoryPosts;
    }

    function createPost(string memory _title, string memory _content) public {
        totalPosts++;

        BlogPost storage post = blogPosts[totalPosts];

        post.id = totalPosts;

        post.author = msg.sender;

        post.title = _title;

        post.content = _content;

        post.likes = 0;

        emit PostCreated(totalPosts, msg.sender, _title, _content);
    }

    function likePost(uint256 _postId) public {
        require(_postId <= totalPosts, "Post does not exist");

        BlogPost storage post = blogPosts[_postId];

        post.likes++;

        emit PostLiked(_postId, msg.sender);
    }

    function getPost(uint256 _postId)
        public
        view
        returns (
            uint256 id,
            address author,
            string memory title,
            string memory content,
            uint256 likes
        )
    {
        require(_postId <= totalPosts, "Post does not exist");

        BlogPost storage post = blogPosts[_postId];

        return (post.id, post.author, post.title, post.content, post.likes);
    }

    function getTotalPosts() public view returns (uint256) {
        return totalPosts;
    }

    function subscribe() public {
        require(
            !subscribers[msg.sender].subscribed,
            "You are already subscribed"
        );

        subscribers[msg.sender] = Subscriber(msg.sender, true);

        emit SubscriberAdded(msg.sender);
    }

    function unsubscribe() public {
        require(subscribers[msg.sender].subscribed, "You are not subscribed");

        delete subscribers[msg.sender];

        emit SubscriberRemoved(msg.sender);
    }

    function isSubscribed(address _subscriber) public view returns (bool) {
        return subscribers[_subscriber].subscribed;
    }
}
