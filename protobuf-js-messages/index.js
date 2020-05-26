const soltype = require(__dirname + "/utils/utils.js");
const BorrowingData = soltype.importTypes(require(__dirname + '/messages/BorrowingData_pb.js'));
const IssuanceData = soltype.importTypes(require(__dirname + '/messages/IssuanceData_pb.js'));
const LendingData = soltype.importTypes(require(__dirname + '/messages/LendingData_pb.js'));
const MultiSwapData = soltype.importTypes(require(__dirname + '/messages/MultiSwapData_pb.js'));
const SwapData = soltype.importTypes(require(__dirname + '/messages/SwapData_pb.js'));
const Transfers = soltype.importTypes(require(__dirname + '/messages/Transfers_pb.js'));
const Payables = soltype.importTypes(require(__dirname + '/messages/Payables_pb.js'));

module.exports = {
  BorrowingData: BorrowingData,
  IssuanceData: IssuanceData,
  LendingData: LendingData,
  Payables: Payables,
  SwapData: SwapData,
  MultiSwapData: MultiSwapData,
  Transfers: Transfers
};
