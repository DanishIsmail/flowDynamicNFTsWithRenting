
import NFTContract from "../contracts/NFTContract.cdc"

pub fun main(account: Address, id: UInt64) : {UInt64: AnyStruct}{
    let account1 = getAccount(account)
    let acct1Capability =  account1.getCapability(NFTContract.CollectionPublicPath)
                            .borrow<&{NFTContract.NFTContractCollectionPublic}>()
                            ??panic("could not borrow receiver reference ")

    var dict : {UInt64: AnyStruct} = {}
    let nftData = acct1Capability.borrowNFTNFTContractContract(id: id)
    var nftMetaData : {String:AnyStruct} = {}    
    nftMetaData["name"] =nftData!.name;
    nftMetaData["description"] = nftData!.description;
    nftMetaData["media"] = nftData!.thumbnail;
    nftMetaData["data"] = nftData!.data;
    nftMetaData["creator"] = nftData!.author;
    nftMetaData["ownerAdress"] = account;
    dict.insert(key: id,nftMetaData)

    return dict
}


