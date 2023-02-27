
import NFTContract from "../contracts/NFTContract.cdc"

pub fun main(account: Address) : {UInt64: AnyStruct}{
    let account1 = getAccount(account)
    let acct1Capability =  account1.getCapability(NFTContract.CollectionPublicPath)
                            .borrow<&{NFTContract.NFTContractCollectionPublic}>()
                            ??panic("could not borrow receiver reference ")

      let nftIds = acct1Capability.getIDs()

    var dict : {UInt64: AnyStruct} = {}

    for nftId in nftIds {
         let nftData = acct1Capability.borrowNFTNFTContractContract(id: nftId)
        var nftMetaData : {String:AnyStruct} = {}
        
        nftMetaData["name"] =nftData!.name;
        nftMetaData["description"] = nftData!.description;
        nftMetaData["media"] = nftData!.thumbnail;
        nftMetaData["data"] = nftData!.data;
        nftMetaData["creator"] = nftData!.author;
        nftMetaData["ownerAdress"] = account;
        dict.insert(key: nftId,nftMetaData)
    }
    return dict
}


 