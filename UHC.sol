pragma solidity ^0.4.16;


// Базовый интерфейс токенов
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// Имплементация базового интерфейса
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

// Для работы с правами владения смартконтрактом
// Наследуемые от Ownable классы автоматически сохраняют owner-а
// И могут использовать модификатор доступа onlyOwner
contract Ownable {
  address public owner;
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}

// Эмит
contract MintableToken is BasicToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  bool public mintingFinished = false;
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// Сжигание нераскупленных токенов, не используется (пока)
contract BurnableToken is MintableToken {
  function burn(uint _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(burner, _value);
  }
  event Burn(address indexed burner, uint indexed value);
}

// UFO Hotel Coin
// Сам Coin
contract UHC is BurnableToken {
  string public constant name = "UFO Hotel Coin";
  string public constant symbol = "UHC";
  uint32 public constant decimals = 0;
  uint256 INITIAL_SUPPLY;
  function UHC(uint supply) public {
    INITIAL_SUPPLY = supply;
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}


// Главный контракт.
contract UFO is Ownable {
  using SafeMath for uint;
  mapping (address => uint) privilegies;
  address multisig;
  uint supply;
//   = 93600000;
  UHC public token;
//   = new UHC(supply);
  uint start;
  uint period;
  uint rate;
  function UFO() public {
    supply = 93600000;
    token = new UHC(supply);
    multisig = 0xEA15Adb66DC92a4BbCcC8Bf32fd25E2e86a2A770; // адрес для эфира
    rate = 1000;
    start = 1522800000;
    period = 7 * 1 days;
  }
  function scheduleSale(uint starttime, uint duration) onlyOwner public {
      start = starttime;
      period = duration;
  }
  function startSale(uint duration) onlyOwner public {
      start = now;
      period = duration;
  }
  function stopSale() onlyOwner public {
      period = 0;
  }
  modifier saleIsOn() {
    require(now > start && now < start + period);
    _;
  }
  function getPrivilegeLevel(address _owner) public view returns(uint level) {
      return privilegies[_owner];
  }
  function createTokens() public saleIsOn payable {
    require(msg.value >= 0);
    multisig.transfer(msg.value);
    uint newtokens = rate.mul(msg.value).div(1 ether);
    token.transfer(msg.sender, newtokens);
    if (newtokens.div(supply) * 100 >= 5)
        privilegies[msg.sender] = 4;
    else if (newtokens >= 100000)
        privilegies[msg.sender] = 3;
    else if (newtokens >= 25000)
        privilegies[msg.sender] = 2;
    else
        privilegies[msg.sender] = 1;
  }
  function() external payable {
    createTokens();
  }
}