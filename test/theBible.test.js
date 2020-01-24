const TheBible = artifacts.require('TheBible');
const catchRevert = require('./exceptionsHelpers').catchRevert;
const BN = web3.utils.BN;

contract('TheBible', accounts => {
  const firstAccount = accounts[0];
  const secondAccount = accounts[1];

  const initialVersePrice = 15000000000000000;
  const provableInitialGasLimit = 500000;

  let instance;

  beforeEach(async () => {
    instance = await TheBible.new();
  });

  describe('setup', () => {
    it('should set owner to be the deploying address', async () => {
      const owner = await instance.owner();

      assert.equal(owner, firstAccount, 'The deploying address should be the owner');
    });

    it(`should set initial verse price to ${initialVersePrice}`, async () => {
      const versePrice = await instance.versePrice();

      assert.equal(versePrice, initialVersePrice, 'Initial verse price should be 0.015 ETH');
    });

    it(`should set initial Provable gas limit to ${provableInitialGasLimit}`, async () => {
      const provableGasLimit = await instance.provableGasLimit();

      assert.equal(provableGasLimit, provableInitialGasLimit, 'Initial Provable gas limit should be 500000');
    });
  })

  describe('setVerse()', () => {
    it('should revert if concatenatedReference value is not provided', async () => {
      await catchRevert(instance.setVerse('', {
        from: firstAccount,
        value: initialVersePrice - 1
      }));
    });

    it('should revert if message value is less than verse price', async () => {
      await catchRevert(instance.setVerse('John/3/16', {
        from: firstAccount,
        value: initialVersePrice - 1
      }));
    });
  });

  describe('processProvableText()', () => {
    it('should revert if Provable result is empty', async () => {
      await catchRevert(instance.processProvableText(''));
    });

    it('should revert if Provable result is missing verse text', async () => {
      await catchRevert(instance.processProvableText('John---3---16---'));
    });

    it('should succeed if Provable result is in correct format', async () => {
      const response = await instance.processProvableText.call('John---3---16---Some text');

      assert.equal(response[0], 'John', 'The book could not be processed correctly')
      assert.equal(response[1], '3', 'The chapter could not be processed correctly')
      assert.equal(response[2], '16', 'The verse could not be processed correctly')
      assert.equal(response[3], 'Some text', 'The verse text could not be processed correctly')
    });
  });

  describe('withdraw()', () => {
    it('reverts if msg sender IS not contract creator', async () => {
      await catchRevert(instance.withdraw({
        from: secondAccount,
        value: 0
      }));
    });

    it('succeeds if msg sender IS NOT contract owner', async () => {
      await instance.withdraw({
        from: firstAccount,
        value: 0
      });
    });
  });

  describe('setProvableGasLimit()', () => {
    it('sets the Provable gas limit if msg sender is contract owner', async () => {
      const newGasLimit = provableInitialGasLimit + 1;

      await instance.setProvableGasLimit(newGasLimit, {
        from: firstAccount,
        value: 0
      });

      const provableGasLimitAfter = await instance.provableGasLimit();

      assert.equal(new BN(provableGasLimitAfter), newGasLimit, 'The Provable gas limit could not be set');
    });

    it('reverts if msg sender is not contract owner', async () => {
      await catchRevert(instance.setProvableGasLimit(provableInitialGasLimit + 1, {
        from: secondAccount,
        value: 0
      }));
    })
  });

  describe('setVersePrice()', () => {
    it ('sets the verse price if msg sender is contract owner', async () => {
      const newVersePrice = 1500000;

      await instance.setVersePrice(newVersePrice, {
        from: firstAccount,
        value: 0
      });

      const versePriceAfter = await instance.versePrice();

      assert.equal(versePriceAfter, newVersePrice, 'The verse price could not be set');
    });

    it('reverts if msg sender is not contract owner', async () => {
      await catchRevert(instance.setVersePrice(150000, {
        from: secondAccount,
        value: 0
      }));
    });
  });
})