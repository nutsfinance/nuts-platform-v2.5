function getAllAccounts(web3) {
  return new Promise((resolve, reject) => {
    web3.eth.getAccounts((err, acc) => {
        if (err) {
          reject(err);
          return;
        }
        resolve(acc);
      });
  });
}

function getInstrumentCode(instrument, artifacts) {
  let instrumentType = instrument.toLowerCase();
  if (instrumentType === 'borrowing') {
    return artifacts.require('./instrument/borrowing/BorrowingInstrument.sol');
  }
  if (instrumentType === 'lending') {
    return artifacts.require('./instrument/lending/LendingInstrument.sol');
  }
  if (instrumentType === 'multi-swap') {
    return artifacts.require('./instrument/multi-swap/MultiSwapInstrument.sol');
  }
  if (instrumentType === 'swap') {
    return artifacts.require('./instrument/swap/SwapInstrument.sol');
  }
  throw "unsupported instrument";
}

function logParser (web3, logs, abi) {
  let events = abi.filter(function (json) {
    return json.type === 'event';
  });

  return logs.map(function (log) {
    let foundAbi = events.find(function(abi) {
      return (web3.eth.abi.encodeEventSignature(abi) == log.topics[0]);
    });
    if (foundAbi) {
      let args = web3.eth.abi.decodeLog(foundAbi.inputs, log.data, foundAbi.anonymous ? log.topics : log.topics.slice(1));
      return {event: foundAbi.name, args: args};
    }
    return null;
  }).filter(p => p != null);
}

module.exports = {
  getInstrumentCode: getInstrumentCode,
  getAllAccounts: getAllAccounts,
  logParser: logParser
};
