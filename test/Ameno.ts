import { ethers, upgrades } from 'hardhat'
import { expect } from 'chai'

describe('Ameno contract tests', () => {
  let Ameno, ameno, owner

  before(async function () {
    ;[owner] = await ethers.getSigners()
    Ameno = await ethers.getContractFactory('Ameno')
    ameno = await upgrades.deployProxy(Ameno, [
      owner.address,
      '$AMENO',
      'AMENO',
      ethers.parseUnits('1000', 18),
      1,
      ethers.parseUnits('1000000', 18),
      ethers.ZeroAddress,
    ])
  })

  describe('Initialization', function () {
    it('should have correct initial values', async function () {
      expect(await ameno.name()).to.equal('$AMENO')
      expect(await ameno.symbol()).to.equal('AMENO')
    })
  })
})
