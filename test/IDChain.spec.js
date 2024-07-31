const IDChain = artifacts.require("IDChain");

contract("IDChain", (accounts) => {
  let instance;

  // Before each test, deploy a new instance of the contract
  beforeEach(async () => {
    instance = await IDChain.new();
  });

  it("should add the deployer as admin", async () => {
    const isAdmin = await instance.admins(accounts[0]);
    assert.isTrue(isAdmin, "The deployer should be an admin");
  });

  it("should create a new KTP", async () => {
    const input = {
      dataHash: "dataHash1",
      photoHash: "photoHash1",
      signatureHash: "signatureHash1"
    };

    await instance.createKTP(input, { from: accounts[1] });

    const ktp = await instance.getKTP(accounts[1]);
    assert.equal(ktp.dataHash, input.dataHash, "Data hash should match");
    assert.equal(ktp.photoHash, input.photoHash, "Photo hash should match");
    assert.equal(ktp.signatureHash, input.signatureHash, "Signature hash should match");
    assert.isFalse(ktp.verified, "KTP should not be verified");
  });

  it("should verify a newly created KTP", async () => {
    const input = {
      dataHash: "dataHash1",
      photoHash: "photoHash1",
      signatureHash: "signatureHash1"
    };

    await instance.createKTP(input, { from: accounts[1] });

    await instance.verifyNewKTP(accounts[1], "NIK123", { from: accounts[0] });

    const ktp = await instance.getKTP(accounts[1]);
    assert.isTrue(ktp.verified, "KTP should be verified");
    assert.equal(ktp.NIK, "NIK123", "NIK should match");
  });

  it("should update an existing KTP", async () => {
    const input = {
      dataHash: "dataHash1",
      photoHash: "photoHash1",
      signatureHash: "signatureHash1"
    };
  
    await instance.createKTP(input, { from: accounts[1] });

    await instance.verifyNewKTP(accounts[1], "NIK123", { from: accounts[0] });
  
    const updatedInput = {
      dataHash: "updatedDataHash",
      photoHash: "updatedPhotoHash",
      signatureHash: "updatedSignatureHash"
    };
  
    await instance.updateKTP(updatedInput, { from: accounts[1] });
  
    const ktp = await instance.getKTP(accounts[1]);
    assert.equal(ktp.dataHash, updatedInput.dataHash, "Data hash should be updated");
    assert.equal(ktp.photoHash, updatedInput.photoHash, "Photo hash should be updated");
    assert.equal(ktp.signatureHash, updatedInput.signatureHash, "Signature hash should be updated");
    assert.isFalse(ktp.verified, "KTP should not be verified after update");
  });
  
  it("should import an existing KTP", async () => {
    const importInput = {
      NIK: "NIK456",
      dataHash: "dataHash2",
      photoHash: "photoHash2",
      signatureHash: "signatureHash2"
    };
  
    await instance.importKTP(importInput, { from: accounts[2] });
  
    const ktp = await instance.getKTP(accounts[2]);
    assert.equal(ktp.NIK, importInput.NIK, "NIK should match");
    assert.equal(ktp.dataHash, importInput.dataHash, "Data hash should match");
    assert.equal(ktp.photoHash, importInput.photoHash, "Photo hash should match");
    assert.equal(ktp.signatureHash, importInput.signatureHash, "Signature hash should match");
    assert.isFalse(ktp.verified, "KTP should not be verified");
  });
  
  it("should remove an admin", async () => {
    await instance.addAdmin(accounts[1], { from: accounts[0] });
    let isAdmin = await instance.admins(accounts[1]);
    assert.isTrue(isAdmin, "The new admin should be added");
  
    await instance.removeAdmin(accounts[1], { from: accounts[0] });
    isAdmin = await instance.admins(accounts[1]);
    assert.isFalse(isAdmin, "The admin should be removed");
  });  
});
