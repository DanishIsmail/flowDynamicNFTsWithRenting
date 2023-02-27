import NFTContract from "../contracts/NFTContract.cdc"

transaction(resourceOwner: Address, name: String, description: String, media: String, recipientAddress: Address) {
    prepare(acct: AuthAccount) {
        let data: {String: String}? = {}
        // NFTContract.mintToken(name: name, description: description, media: media, data: data, recipientAddress: recipientAddress)
        let account = getAccount(resourceOwner)
        let adminRef = account.getCapability(NFTContract.NFTAdminResourcePublicPath)
            .borrow<&{NFTContract.NFTAdminResourcePublic}>()
            ?? panic("Could not borrow public sale reference")
        adminRef.mintToken(name: name, description: description, media: media, data: data, recipientAddress: recipientAddress)
    }

    execute {
        log("nft minted")
    }
}