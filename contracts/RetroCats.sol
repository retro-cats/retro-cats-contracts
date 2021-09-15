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
import "../interfaces/KeeperCompatibleInterface.sol";

contract RetroCats is Ownable, ERC721URIStorage, VRFConsumerBase, ReentrancyGuard, KeeperCompatibleInterface{
    using Strings for uint256;
    
    // ERC721 Variables
    uint256 public s_tokenCounter;
    string internal s_baseURI;

    // Chainlink VRF Variables
    bytes32 internal s_keyHash;
    uint256 public s_fee;
    uint256 internal s_recentRandomNumber;
    mapping(bytes32 => uint256) internal s_requestIdToTokenId;
    mapping(uint256 => uint256) public s_tokenIdToRandomNumber;

    // Chainlink Keeper Variables
    address public s_chainlinkKeeperRegistryContract;
    // Retro Cat Randomness Variables
    /**
    * @dev Every X cats minted will trigger a new random
    * number from the chainlink VRF. That X number, is this
    * variable.
    */
    uint256 public s_vrfCallInterval;
    uint256[] public s_tokenIdRandomnessNeededQueue;
    address public s_retroCatsMetadata;
    uint256 public s_catfee;
    /**
    * @dev Every X cats minted will trigger a new random
    * number from the chainlink VRF. That X number, is this
    * variable.
    */

    // Events
    event requestedNewChainlinkVRF(bytes32 indexed requestId);
    event requestedNewCat(uint256 tokenId);
    event randomNumberAssigned(uint256 indexed tokenId, uint256 indexed randomNumber);

    /**
    * @notice Deploys the retrocats factory contract
    * @param _vrfCoordinator The address of the VRF Coordinator 
    * The VRF Coordinator does the due dilligence to ensure
    * the number returned is truly random. 
    * @param _linkToken The address of the Chainlink token
    */
    constructor (address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee, address _retroCatsMetadata, address _chainlinkKeeperRegistryContract, uint256 _vrfCallInterval) public
    VRFConsumerBase(_vrfCoordinator, _linkToken)
    ERC721("Retro Cats", "RETRO")
    {
        s_tokenCounter = 0;
        s_keyHash = _keyHash;
        s_fee = _fee;
        s_vrfCallInterval = _vrfCallInterval;
        s_retroCatsMetadata = _retroCatsMetadata;
        s_chainlinkKeeperRegistryContract = _chainlinkKeeperRegistryContract;
        s_baseURI = "https://us-central1-retro-cats.cloudfunctions.net/retro-cats-function?token_id=";
        s_catfee = 20000000000000000;
    }

    /**
    * @notice Mints a new random cat
    * @dev We only trigger a chainlink VRF call every s_vrfCallInterval mints.
    * Otherwise, we will have the Chainlink Keeper Network create our 
    * random number, so others can't exploit searching for randomness.
    * We do this as a cost saving mechanism. Since keepers is cheaper than 
    * Chainlink VRF calls, but we still want true randomness. 
    */
    function mint_cat() public payable nonReentrant returns (uint256 tokenId){
        require(msg.value >= s_catfee, "You must pay the cat fee!");
        tokenId = s_tokenCounter;
        _safeMint(msg.sender, tokenId);

        if(s_tokenCounter % s_vrfCallInterval == 0){
            bytes32 requestId = requestRandomness(s_keyHash, s_fee);
            s_requestIdToTokenId[requestId] = tokenId;
            emit requestedNewCat(tokenId);
            emit requestedNewChainlinkVRF(requestId);
        } else { 
            s_tokenIdRandomnessNeededQueue.push(tokenId);
            emit requestedNewCat(tokenId);
        }
        s_tokenCounter = s_tokenCounter + 1;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        s_recentRandomNumber = randomness;
        uint256 tokenId = s_requestIdToTokenId[requestId];
        s_tokenIdToRandomNumber[tokenId] = randomness;
        emit randomNumberAssigned(tokenId, randomness);
    }

    function setVRFCallInterval(uint256 newInterval) public onlyOwner {
        s_vrfCallInterval = newInterval;
    }

    /**
    * @notice Checks to see if their are any tokenIds that don't have 
    * a random number & tokenURI associated with them
    * @param checkData should be empty, needed for keeper network
    */
    function checkUpkeep(bytes calldata checkData) external override returns (bool upkeepNeeded, bytes memory performData){
        upkeepNeeded = s_tokenIdRandomnessNeededQueue.length > 0;
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override onlyChainlinkKeepers{
        require(s_tokenIdRandomnessNeededQueue.length > 0, "RetroCats: There is nothing in queue!");
        uint256 tokenQueueIndex = 0;
        uint256 tokenId = s_tokenIdRandomnessNeededQueue[tokenQueueIndex];
        // maybe we loop through a group of 10 (or 10 - tokenCounter % interval) 
        // instead of just doing 1 at a time
        // This might be an attack vector though
        uint256 newRandomNumber = uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.number, block.timestamp, tx.origin, tx.gasprice, tokenId)
                )
            );
        s_tokenIdToRandomNumber[tokenId] = newRandomNumber;
        emit randomNumberAssigned(tokenId, newRandomNumber);
        removeFromQueue(tokenQueueIndex);
    }

    // refactor for gas please
    function removeFromQueue(uint256 index) internal {
        if (index >= s_tokenIdRandomnessNeededQueue.length) return;

        for (uint i = index; i<s_tokenIdRandomnessNeededQueue.length-1; i++){
            s_tokenIdRandomnessNeededQueue[i] = s_tokenIdRandomnessNeededQueue[i+1];
        }
        s_tokenIdRandomnessNeededQueue.pop();
    }


    // Only the Chainlink keeper registery should be able to call this contract
    modifier onlyChainlinkKeepers() {
        require(msg.sender == s_chainlinkKeeperRegistryContract, "RetroCats: Caller is not a Chainlink Node!");
        _;
    }

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
     * @dev Sets the BaseURI for computing {tokenURI}. 
     */
    function _setBaseURI(string memory _baseURI) public onlyOwner(){
        s_baseURI = _baseURI;
    }

    function _setRetroCatMetadata(address _retroCatMetadata) public onlyOwner(){
        s_retroCatsMetadata = _retroCatMetadata;
    }

    function setCatFee(uint256 _catfee) public onlyOwner {
        s_catfee = _catfee;
    }

    function withdraw() public onlyOwner{
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface linkToken = LinkTokenInterface(LINK);
        require(linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))), "Unable to transfer");
    }

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
}
