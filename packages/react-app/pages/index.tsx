import { useCelo } from "@celo/react-celo";
import { title } from "process";
import { useEffect, useState, useCallback } from "react";
const blog = require("../../hardhat/deployments/alfajores/DecentralizedBlog.json");

export const PostCard = ({
	title,
	description,
	likes,
	author,
	handleClick,
}: any) => {
	if (title === "") {
		return;
	}

	return (
		<div className="bg-white  shadow-lg rounded-lg overflow-hidden m-2   transition ease-in-out hover:-translate-y-1 duration-300">
			<div className="pr-24 ">
				<div className="my-3 p-2">
					<div className="my-1 text-lg text-gray-600 ">Title</div>
					<div className="text-3xl text-gray-600 font-semibold">{title}</div>
				</div>
				<div className="my-3 p-2 font-medium text-gray-600 text-xl">
					<div className="my-1 text-lg text-gray-600 ">Description</div>
					<div className="text-3xl text-gray-600 font-semibold">
						{description}
					</div>
				</div>

				<div className="my-3 p-2 font-medium text-gray-600 text-xl">
					<div className="my-1 text-lg text-gray-600 overflow-y-scroll">
						Author
					</div>
					<div className="text-3xl text-gray-600 font-semibold">{author}</div>
				</div>
				<div className="my-3 p-2 font-medium text-gray-600 text-xl">
					<div className="my-1 text-lg text-gray-600 ">likes</div>
					<div className="text-3xl text-gray-600 font-semibold">
						{likes} likes
					</div>
				</div>
				<button
					onClick={handleClick}
					className="my-6 bg-blue-400 py-3 px-6 rounded-xl ml-4 hover:bg-rose-600 ">
					Like
				</button>
			</div>
		</div>
	);
};

export default function Home() {
	const { connect, address, kit, getConnectedKit } = useCelo();
	const [subscribed, setSubscribed] = useState(false);
	const [name, setName] = useState("");
	const [description, setDescription] = useState("");
	const [posts, setPosts] = useState<any>([]);
	const numPosts = 6;

	const contract = new kit.connection.web3.eth.Contract(blog.abi, blog.address);

	const handleSubmit = async (event: { preventDefault: () => void }) => {
		event.preventDefault();

		if (!address) {
			return;
		}
		if (!name || !description) {
			return;
		}
		if (!contract) {
			return;
		}

		const tx = await contract.methods
			.createPost(name, description)
			.send({ from: address });
		console.log(tx);
	};

	useEffect(() => {
		async function fetchPosts() {
			const data2: any[] = [];
			if (!address) {
				return;
			}
			if (subscribed) {
				return alert("You must be a subscriber to post");
			}
			const totalPostNum = await contract.methods.totalPosts().call();
			console.log("Total posts:", totalPostNum);
			for (let i = 0; i <= totalPostNum; i++) {
				await contract.methods
					.getPost(i)
					.call()
					.then((res: any) => {
						data2.push(res);
					});
				// const { title, zcontent, likes } = post;
				// data2.push(post);

				setPosts(data2);
				console.log("Posts:", posts);
			}
		}
		fetchPosts();
	}, []);

	const postSubscribe = async () => {
		if (!address) {
			return;
		}
		const tx = await contract.methods
			.subscribe()
			.send({ from: address, gas: 1000000 });
		console.log(tx);
		setSubscribed(true);
	};

	const postLike = async (id: number) => {
		if (!address) {
			return;
		}
		const tx = await contract.methods.likePost(id).send({ from: address });
		console.log(tx);
	};

	return (
		<div className="flex flex-1 flex-col min-h-screen">
			<div className="flex flex-row justify-between items-center ">
				<div>
					<div className="text-4xl font-semibold">
						Welcome to our decentralized anonymous blog
					</div>
					<div>You must first be a subscriber</div>
					<button
						onClick={postSubscribe}
						className="mt-4 bg-blue-400 py-2 px-6 text-white text-xl font-semibold rounded-xl">
						Subscribe
					</button>
				</div>
				<div className="mr-16">
					<div className="text-3xl font-semibold">Create a Post</div>
					<div className="my-4 border bg-white px-3 py-12 rounded-xl">
						<form onSubmit={handleSubmit} className="px-6 pb-8">
							<div className="mt-0 mb-6">
								<label
									className="block text-gray-500 font-semibold mb-6 text-2xl"
									htmlFor="name">
									Title
								</label>
								<input
									className="border-2 rounded-md w-full py-2 px-6 text-gray-600 leading-tight focus:outline-none focus:shadow-outline mb-6"
									id="name"
									type="text"
									placeholder="Project name"
									value={name}
									onChange={(e) => setName(e.target.value)}
								/>
							</div>
							<div className="mb-4">
								<label
									className="block text-gray-500 font-semibold mb-2 text-2xl"
									htmlFor="description">
									Description
								</label>
								<textarea
									className="border-2 rounded-md w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
									id="description"
									placeholder="Project description"
									value={description}
									onChange={(e) => setDescription(e.target.value)}
								/>
							</div>

							<button
								onClick={handleSubmit}
								className="mt-4 bg-blue-400 py-2 px-6 text-white text-xl font-semibold rounded-xl"
								type="submit">
								Submit
							</button>
						</form>
					</div>
				</div>
			</div>

			<div className="flex flex-col">
				<div>Recent Posts</div>
				<div className="flex flex-row overflow-x-scroll">
					{posts.map((post: any) => (
						<PostCard
							key={post.id}
							title={post.title}
							description={post.content}
							author={post.author}
							likes={post.likes}
							handleClick={() => postLike(post.id)}
						/>
					))}
				</div>
			</div>
		</div>
	);
}
