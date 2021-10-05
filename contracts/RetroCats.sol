/** 
██████╗ ███████╗████████╗██████╗  ██████╗      ██████╗ █████╗ ████████╗███████╗    
██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    
██████╔╝█████╗     ██║   ██████╔╝██║   ██║    ██║     ███████║   ██║   ███████╗    
██╔══██╗██╔══╝     ██║   ██╔══██╗██║   ██║    ██║     ██╔══██║   ██║   ╚════██║    
██║  ██║███████╗   ██║   ██║  ██║╚██████╔╝    ╚██████╗██║  ██║   ██║   ███████║    
╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝      ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝    
                                                                                 

<<https://github.com/retro-cats/retro-cats-contracts>>

           __..--''``---....___   _..._    __
       _.-'    .-/";  `        ``<._  ``.''_ `. / // /
   _.-' _..--.'_    \                    `( ) ) // //
   (_..-' // (< _     ;_..__               ; `' / ///
 //// // //  `-._,_)' // / ``--...____..-' /// / //
*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RetroCats is Ownable, ERC721URIStorage, VRFConsumerBase, ReentrancyGuard{
    using Strings for uint256;
    
    // ERC721 Variables
    uint256 public s_tokenCounter;
    string internal s_baseURI;

    // Chainlink VRF Variables
    bytes32 internal s_keyHash;
    uint256 public s_fee;
    mapping(bytes32 => uint256) internal s_requestIdToStartingTokenId;
    mapping(bytes32 => uint256) internal s_requestIdToAmount;
    mapping(uint256 => uint256) public s_tokenIdToRandomNumber;
    // Retro Cat Randomness Variables
    address public s_retroCatsMetadata;
    uint256 public s_catfee;
    uint256 public s_maxCatMint;

    // Events
    event requestedNewCat(uint256 indexed tokenId, bytes32 requestId);
    event randomNumberAssigned(uint256 indexed tokenId, uint256 indexed randomNumber);

    /**
    * @notice Deploys the retrocats factory contract
    * @param _vrfCoordinator The address of the VRF Coordinator 
    * The VRF Coordinator does the due dilligence to ensure
    * the number returned is truly random. 
    * @param _linkToken The address of the Chainlink token
    */
    constructor (address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee, address _retroCatsMetadata) 
    VRFConsumerBase(_vrfCoordinator, _linkToken)
    ERC721("Retro Cats", "RETRO")
    {
        s_tokenCounter = 0;
        s_keyHash = _keyHash;
        s_fee = _fee;
        s_retroCatsMetadata = _retroCatsMetadata;
        s_baseURI = "https://us-central1-retro-cats.cloudfunctions.net/retro-cats-function?token_id=";
        s_catfee = 20000000000000000;
        s_maxCatMint = 10;
    }

    /**
    * @notice Mints a new random cat
    * We use Chainlink VRF to request a random number
    * that random number is assigned to a cat, and is it's "dna"
    * the `fulfillrandomness` function, is the function that does the assigning
    * if they minted more than 1 cat, they will use the `expandedRandomness` function
    * to mint more random numbers from the 1. 
    */
    function mint_cats(uint256 _amount) public payable nonReentrant returns (uint256 tokenId){
        require(msg.value >= s_catfee * _amount, "You must pay the cat fee!");
        require(s_maxCatMint >= _amount, "You can't mint more than the max amount of cats at once!");
        require(_amount > 0, "Uh.... Mint at least 1 please");
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK in contract");
        for(uint256 i = 0; i < _amount; i++){
            tokenId = s_tokenCounter;
            _safeMint(msg.sender, tokenId);
            bytes32 requestId = requestRandomness(s_keyHash, s_fee);
            s_requestIdToStartingTokenId[requestId] = tokenId;
            s_requestIdToAmount[requestId] = _amount;
            emit requestedNewCat(tokenId, requestId);
            s_tokenCounter = s_tokenCounter + 1;
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. 
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 tokenId = s_requestIdToStartingTokenId[requestId];
        uint256 amount = s_requestIdToAmount[requestId];
        for (uint256 i = tokenId; i < tokenId + amount; i++){
            s_tokenIdToRandomNumber[i] = expandedRandomness(randomness, i);
            emit randomNumberAssigned(i, s_tokenIdToRandomNumber[i]);
        }
    }

    /**
     * @dev Allows us to get many random numbers from just 1
     */
    function expandedRandomness(uint256 randomValue, uint256 n) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(randomValue, n)));
    }

    /**
     * @dev For if a user wants to immortalize their cat in IPFS
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Base URI for computing {tokenURI}. 
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return s_baseURI;
    }

    /**
     * @dev withdraw the ETH earned from the contract. 
     */
    function withdraw() public nonReentrant onlyOwner{
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
    }

    /**
     * @dev Withdraw the LINK from the contract. 
     */
    function withdrawLink() public onlyOwner nonReentrant {
        LinkTokenInterface linkToken = LinkTokenInterface(LINK);
        require(linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))), "Unable to transfer");
    }

    /**
     * @dev TokenURI for the NFTs.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    
    // ********* setter functions **********
    function _setBaseURI(string memory _newBaseURI) public onlyOwner(){
        s_baseURI = _newBaseURI;
    }

    function _setRetroCatMetadata(address _retroCatMetadata) public onlyOwner(){
        s_retroCatsMetadata = _retroCatMetadata;
    }

    function setCatFee(uint256 _catfee) public onlyOwner {
        s_catfee = _catfee;
    }

    function setKeyHash(bytes32 _newKeyHash) public onlyOwner nonReentrant {
        s_keyHash = _newKeyHash;
    }

    function setFee(uint256 _newFee) public onlyOwner nonReentrant {
        s_fee = _newFee;
    }

    function setMaxCatMint(uint256 _newMaxCatMint) public onlyOwner nonReentrant {
        s_maxCatMint = _newMaxCatMint;
    }
}
