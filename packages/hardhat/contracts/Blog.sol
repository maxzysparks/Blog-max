// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;



contract DecentralizedBlog {

    struct BlogPost {

        uint256 id;

        address author;

        string title;

        string content;

        uint256 likes;

    }



    struct Subscriber {

        address subscriberAddress;

        bool subscribed;

    }



    uint256 public totalPosts;

    mapping(uint256 => BlogPost) public blogPosts;

    mapping(address => Subscriber) public subscribers;



    event PostCreated(uint256 indexed id, address indexed author, string title, string content);

    event PostLiked(uint256 indexed id, address indexed liker);

    event SubscriberAdded(address indexed subscriber);

    event SubscriberRemoved(address indexed subscriber);



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



    function getPost(uint256 _postId) public view returns (uint256 id, address author, string memory title, string memory content, uint256 likes) {

        require(_postId <= totalPosts, "Post does not exist");

        BlogPost storage post = blogPosts[_postId];

        return (post.id, post.author, post.title, post.content, post.likes);

    }



    function getTotalPosts() public view returns (uint256) {

        return totalPosts;

    }



    function subscribe() public {

        require(!subscribers[msg.sender].subscribed, "You are already subscribed");

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

