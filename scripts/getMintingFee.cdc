
import NFTContract from "../contracts/NFTContract.cdc"

pub fun main() : UFix64 {
    return NFTContract.getMintingFee()
}
