import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NFTContract from "../contracts/NFTContract.cdc"


transaction(withdrawID: UInt64) {
    let transferToken: @NonFungibleToken.NFT
    prepare(acct: AuthAccount) {
        let collectionRef =  acct.borrow<&NFTContract.Collection>(from: NFTContract.CollectionStoragePath)
        ??panic("could not borrow a reference to the stored nft Collection")
        self.transferToken <- collectionRef.withdraw(withdrawID: withdrawID)
    }

    execute {
        destroy self.transferToken
    }
}