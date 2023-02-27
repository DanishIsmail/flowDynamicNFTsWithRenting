
import NFTContract from "../contracts/NFTContract.cdc"
import MetadataViews from "../contracts/MetadataViews.cdc"

pub fun main(id: UInt64, account: Address) : &AnyResource{MetadataViews.Resolver} {
    let account1 = getAccount(account)
    let acct1Capability =  account1.getCapability(NFTContract.CollectionPublicPath)
                            .borrow<&{NFTContract.NFTContractCollectionPublic}>()
                            ??panic("could not borrow receiver reference ")

    return acct1Capability.borrowViewResolver(id: id)
}
