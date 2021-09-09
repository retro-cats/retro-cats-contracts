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

import "@openzeppelin-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/StringsUpgradeable.sol";

contract RetroCatsUpgraded is Initializable, OwnableUpgradeable, ERC721URIStorageUpgradeable, ReentrancyGuardUpgradeable{
    using StringsUpgradeable for uint256;
    
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
    function initialize(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee, address _retroCatsMetadata, address _chainlinkKeeperRegistryContract) initializer public
    {
        __ERC721_init_unchained("Retro Cats", "RETRO");
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        s_tokenCounter = 0;
        s_keyHash = _keyHash;
        s_fee = _fee;
        s_vrfCallInterval = 15;
        s_retroCatsMetadata = _retroCatsMetadata;
        s_chainlinkKeeperRegistryContract = _chainlinkKeeperRegistryContract;
        s_baseURI = "https://us-central1-retro-cats.cloudfunctions.net/retro-cats-function?token_id=";
    }

    function test_working() public view returns (bool) {
        return true;
    }
}
