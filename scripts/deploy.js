async function main() {
    const [owner] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", owner.address);

    console.log("Account balance:", (await owner.getBalance()).toString());

    const myNFT = await ethers.getContractFactory("NFTItem");
    
    const nft = await myNFT.deploy();

    console.log("Contract Address:", (await nft.address));
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});