import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NFTContract from "../contracts/NFTContract.cdc"


transaction() {
    prepare(acct: AuthAccount) {
        // store the empty NFT Collection in account storage 
        acct.save(<- NFTContract.createEmptyCollection(), to: NFTContract.CollectionStoragePath)
        // create a public capability for the Collection
        acct.link<&{NFTContract.NFTContractCollectionPublic}>(NFTContract.CollectionPublicPath, target: NFTContract.CollectionStoragePath)
    }

    execute {
        log("collection setup")
    }
}
