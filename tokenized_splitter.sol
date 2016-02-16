contract TokenizedSplitter {

    struct Account {
        bool activated;
        uint248 tokens;
        uint cash;
    }

    mapping (address => Account) accounts;
    address[] accountAddresses;

    uint totalTokens;
    uint allocatedCash;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function TokenizedSplitter(uint248 total) external {
        totalTokens = total;
        accounts[msg.sender].activated = true;
        accounts[msg.sender].tokens = total;
        accountAddresses.push(msg.sender);
    }

    function totalSupply() constant external returns (uint256 supply) {
        return totalTokens;
    }

    function balanceOf(address _owner) constant external returns (uint256 balance) {
        balance = accounts[_owner].tokens;
    }

    function allocateCash() {

        uint unallocatedCash = this.balance - allocatedCash;

        if (unallocatedCash == 0) {
            return;
        }

        for (uint i = 0; i < accountAddresses.length; i++) {
            Account account = accounts[accountAddresses[i]];
            if (account.tokens != 0) {
                // Rounds down. A very small amount of dust may be lost.
                account.cash += (unallocatedCash * account.tokens) / totalTokens;
            }
        }

        allocatedCash = this.balance;
    }

    function cashout(address destination) external {
        allocateCash();
        Account account = accounts[msg.sender];
        uint amount = account.cash;
        destination.send(amount);
        allocatedCash -= amount;
        account.cash = 0;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        allocateCash();
        Account fromAccount = accounts[msg.sender];
        Account toAccount = accounts[_to];

        if (fromAccount.tokens < _value) {
            return false;
        }
        if (toAccount.activated == false) {
            toAccount.activated = true;
            accountAddresses.push(_to);
        }
        fromAccount.tokens -= uint248(_value);
        toAccount.tokens += uint248(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

}
