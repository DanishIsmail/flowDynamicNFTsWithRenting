import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import FungibleToken from "./FungibleToken.cdc"
import FlowToken from 0x0ae53cb6e3f42a79

pub contract NFTContract: NonFungibleToken {
    
    // -----------------------------------------------------------------------
    // NFT contract Event definitions
    // -----------------------------------------------------------------------
    // Emitted when contract initalized
    pub event ContractInitialized()
    // Emitted when NFT withdrawn
    pub event Withdraw(id: UInt64, from: Address?)
    // Emitted when NFT Deposit
    pub event Deposit(id: UInt64, to: Address?)
    // Emitted when NFT created
    pub event NFTMinted(id: UInt64)
    // Emitted when NFT destroyed
    pub event NFTDestroyed(id: UInt64)
    
    // Contract level paths for storing resources
    pub let CollectionStoragePath: StoragePath
    pub let NFTAdminResourceStoragePath: StoragePath
    pub let NFTAdminResourcePublicPath: PublicPath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionPrivatePath: PrivatePath

    // NFTContract state level variables 
    // variable to store the total suply 
    pub var totalSupply: UInt64
    //variable to hold the minting fee 
    pub var tokenMintingFee: UFix64
    // variable to store the minting fee
    // The Vault of the Marketplace where it will receive the cuts on each sale
    pub let ownerVault: Capability<&FlowToken.Vault{FungibleToken.Receiver}>

    /*
    * NFT
    *   NFT is a resource that actually stays in user storage.
    *   NFT has id, ipfsHash,  and metadata which include details of that specific NFT
    */
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        pub let author: Address
        pub let data: {String: String}?

        init(name: String, description: String, media: String, author: Address,data: {String: String}?) {
            NFTContract.totalSupply = NFTContract.totalSupply + 1
            self.id = NFTContract.totalSupply
            self.name = name
            self.thumbnail = media
            self.description = description
            self.author = author
            self.data = data
            

            emit NFTMinted(id: self.id)
        }

        destroy(){
            emit NFTDestroyed(id: self.id)
        }
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }
         pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
            }

            return nil
        } 
        
    }


    /** NFTContractCollectionPublic
    *   A public interface extending the standard NFT Collection with type information specific
    *   to NFTContract NFTs.
    */
    pub resource interface NFTContractCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
       // pub fun borrowEntireNFT(id: UInt64): &NFTContract.NFT
        pub fun borrowNFTNFTContractContract(id: UInt64): &NFTContract.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Reward reference: The ID of the returned reference is incorrect"
            }
        }
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver}
    }

    /** Collection
    *   Collection is a resource that lie in user storage to manage owned NFT resource
    */
    pub resource Collection: NFTContractCollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic {
        // ownedNFTs will manage all user owned NFTs against it NFT id
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw method will withdraw NFT from NFT id from user storage
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) 
                ?? panic("Cannot withdraw: The NFT does not exist in the collection")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <- token
        }
        
        // deposit method will store NFT into user storage 
        pub fun deposit(token: @NonFungibleToken.NFT) {
            // Cast the deposited token as a NFTContract NFT to make sure
            // it is the correct type
            let token <- token as! @NFTContract.NFT
            // Get the token's ID
            let id = token.id
            // Add the new token to the dictionary
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner!.address)
            destroy oldToken
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowNFTNFTContractContract returns a borrowed reference to a NFTContractNFT
        // so that the caller can read data and call methods from it.
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        pub fun borrowNFTNFTContractContract(id: UInt64): &NFTContract.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &NFTContract.NFT
            } else {
                return nil
            }
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let exampleNFT = nft as! &NFTContract.NFT
            return exampleNFT as!  &AnyResource{MetadataViews.Resolver}
        }

        init() {
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }
   
    pub resource interface NFTAdminResourcePublic {
        pub fun mintToken(name: String, description: String, media: String, data: {String: String}?, recipientAddress: Address)
     }
    pub resource NFTAdminResource: NFTAdminResourcePublic {
         // methods to mint the NFT Token
        pub fun mintToken(name: String, description: String, media: String, data: {String: String}?, recipientAddress: Address) {
            let receiptAccount = getAccount(recipientAddress)
            let recipientCollection = receiptAccount
                .getCapability(NFTContract.CollectionPublicPath)
                .borrow<&{NFTContract.NFTContractCollectionPublic}>()
                ?? panic("Could not get receiver reference to the NFT Collection")
            var newNFT: @NFT <- create NFT(name: name, description: description, media: media, author: recipientAddress,data: data)
            recipientCollection.deposit(token: <-newNFT)
        }

        // method to set the Minting fee for tokens
        pub fun setMintingFee(mintngfee: UFix64) {
            pre {
                mintngfee > UFix64(0.0): "minting fee should be greater then 0.0" 
            }
            NFTContract.tokenMintingFee = mintngfee
        }

    }

   
    // method to create user empty collection 
    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    // method to get the Minting fee for tokens
     pub fun getMintingFee(): UFix64 {
       return self.tokenMintingFee 
    }

    init() {
        self.totalSupply = 0
        self.tokenMintingFee = 0.0
        self.ownerVault = self.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)

        self.CollectionStoragePath = /storage/NFTContractNFTCollection
        self.NFTAdminResourceStoragePath = /storage/NFTAdminResourceStoragePath
        self.CollectionPublicPath = /public/NFTContractNFTCollection
        self.NFTAdminResourcePublicPath = /public/NFTAdminResourcePublicPath
        self.CollectionPrivatePath = /private/NFTContractNFTCollection

        self.account.save(<- create NFTAdminResource(), to: self.NFTAdminResourceStoragePath)
        self.account.link<&{NFTContract.NFTAdminResourcePublic}>(self.NFTAdminResourcePublicPath, target: self.NFTAdminResourceStoragePath)
        

        emit ContractInitialized()
    }
}