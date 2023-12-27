// ┏┓┳┳┓┏┓┳┓┏┓
// ┣┫┃┃┃┣ ┃┃┃┃
// ┛┗┛ ┗┗┛┛┗┗┛

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/// @custom:security-contact ameno@bdut.ch
contract Ameno is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  ERC20PausableUpgradeable,
  OwnableUpgradeable,
  ERC20PermitUpgradeable,
  ERC20VotesUpgradeable,
  ERC20FlashMintUpgradeable,
  ReentrancyGuardUpgradeable
{
  // State
  uint256 public mintRate;
  uint256 public supplyCap;
  address public amenoGod;

  // claimer => ticketType => lastClaimTimestamp
  mapping(uint256 => mapping(uint256 => bool)) public amenoClaimsUsed;
  mapping(uint256 => mapping(uint256 => bool)) public ethClaimsUsed;

  // Events
  event MintRateSet(uint256 newMintRate);
  event SupplyCapSet(uint256 newSupplyCap);
  event AmenoGodSet(address newAmenoGod);
  event SangDorime(address indexed singer);
  event SangAmeno(address indexed singer);
  event ClaimedAmeno(
    address indexed claimer,
    uint256 ticketType,
    uint256 amount
  );
  event ClaimedEth(address indexed claimer, uint256 ticketType, uint256 amount);

  function initialize(
    address initialOwner,
    string calldata name,
    string calldata symbol,
    uint256 premintAmount,
    uint256 initialMintRate,
    uint256 initialSupplyCap,
    address initialAmenoGod
  ) public initializer {
    mintRate = initialMintRate;
    supplyCap = initialSupplyCap;
    amenoGod = initialAmenoGod;

    __ERC20_init(name, symbol);
    __ERC20Burnable_init();
    __ERC20Pausable_init();
    __Ownable_init(initialOwner);
    __ERC20Permit_init(name);
    __ERC20Votes_init();
    __ERC20FlashMint_init();

    _mint(initialOwner, premintAmount);
  }

  function setMintRate(uint256 newMintRate) public onlyOwner {
    mintRate = newMintRate;
    emit MintRateSet(newMintRate);
  }

  function setSupplyCap(uint256 newSupplyCap) public onlyOwner {
    supplyCap = newSupplyCap;
    emit SupplyCapSet(newSupplyCap);
  }

  function setAmenoGod(address newAmenoGod) public onlyOwner {
    amenoGod = newAmenoGod;
    emit AmenoGodSet(newAmenoGod);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function withdraw(uint256 amount) public onlyOwner {
    require(amount <= address(this).balance, "Insufficient balance");
    payable(owner()).transfer(amount);
  }

  function mint() public payable nonReentrant {
    require(msg.value > 0, "No Ether sent");
    uint256 amountToMint = msg.value * mintRate;
    require(totalSupply() + amountToMint <= supplyCap, "Supply cap exceeded");
    _mint(msg.sender, amountToMint);
  }

  // Claims

  function claimAmeno(
    bytes calldata data,
    bytes32 r,
    bytes32 vs
  ) public nonReentrant {
    (address recoveredAmenoGod, ECDSA.RecoverError ecdsaError, ) = ECDSA
      .tryRecover(MessageHashUtils.toEthSignedMessageHash(data), r, vs);
    require(
      ecdsaError == ECDSA.RecoverError.NoError,
      "Error while verifying the ECDSA signature"
    );
    require(
      recoveredAmenoGod == amenoGod,
      "You're praying to the wrong Ameno God, beware!"
    );
    (uint256 claimer, uint256 ticketType, uint256 amount) = abi.decode(
      data,
      (uint256, uint256, uint256)
    );
    require(
      !amenoClaimsUsed[claimer][ticketType],
      "You little rascal, you already claimed this ticket!"
    );
    _mint(msg.sender, amount);
    amenoClaimsUsed[claimer][ticketType] = true;
    emit ClaimedAmeno(msg.sender, ticketType, amount);
  }

  function claimEth(
    bytes calldata data,
    bytes32 r,
    bytes32 vs
  ) public nonReentrant {
    (address recoveredAmenoGod, ECDSA.RecoverError ecdsaError, ) = ECDSA
      .tryRecover(MessageHashUtils.toEthSignedMessageHash(data), r, vs);
    require(
      ecdsaError == ECDSA.RecoverError.NoError,
      "Error while verifying the ECDSA signature"
    );
    require(
      recoveredAmenoGod == amenoGod,
      "You're praying to the wrong Ameno God, beware!"
    );
    (uint256 claimer, uint256 ticketType, uint256 amount) = abi.decode(
      data,
      (uint256, uint256, uint256)
    );
    require(
      !ethClaimsUsed[claimer][ticketType],
      "You little rascal, you already claimed this ticket!"
    );
    require(
      address(this).balance >= amount,
      "Not enough Ether in the contract"
    );
    payable(msg.sender).transfer(amount);
    ethClaimsUsed[claimer][ticketType] = true;
    emit ClaimedEth(msg.sender, ticketType, amount);
  }

  // Crucial actions

  function singDorime() public {
    emit SangDorime(msg.sender);
  }

  function singAmeno() public {
    emit SangAmeno(msg.sender);
  }

  // The following functions are overrides required by Solidity.

  function _update(
    address from,
    address to,
    uint256 value
  )
    internal
    override(ERC20Upgradeable, ERC20PausableUpgradeable, ERC20VotesUpgradeable)
  {
    super._update(from, to, value);
  }

  function nonces(
    address owner
  )
    public
    view
    override(ERC20PermitUpgradeable, NoncesUpgradeable)
    returns (uint256)
  {
    return super.nonces(owner);
  }
}
