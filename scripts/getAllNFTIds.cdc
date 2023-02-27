
import NFTContract from "../contracts/NFTContract.cdc"

pub fun main(account: Address) : [UInt64]{
    let account1 = getAccount(account)
    let acct1Capability =  account1.getCapability(NFTContract.CollectionPublicPath)
                            .borrow<&{NFTContract.NFTContractCollectionPublic}>()
                            ??panic("could not borrow receiver reference ")

    return acct1Capability.getIDs()
}
