import NFTContract from "../contracts/NFTContract.cdc"

transaction(mintngfee: UFix64) {
    prepare(acct: AuthAccount) {
        // NFTContract.setMintingFee(mintngfee: mintngfee)
          let adminRef = acct.borrow<&NFTContract.NFTAdminResource>(from: NFTContract.NFTAdminResourceStoragePath)
                     ?? panic("could not borrow admin refrence")
        adminRef.setMintingFee(mintngfee: mintngfee)
    }

    execute {
        log("nft minted")
    }
}