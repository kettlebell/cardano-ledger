{-# LANGUAGE TemplateHaskell #-}

module Cardano.Ledger.Plutus.Preprocessor.Source.V3 where

import Language.Haskell.TH
import qualified PlutusLedgerApi.V3 as PV3
import PlutusTx (fromBuiltinData, unsafeFromBuiltinData)
import qualified PlutusTx.AssocMap as PAM
import qualified PlutusTx.Builtins as P
import qualified PlutusTx.Prelude as P

alwaysSucceedsNoDatumQ :: Q [Dec]
alwaysSucceedsNoDatumQ =
  [d|
    alwaysSucceedsNoDatum :: P.BuiltinData -> ()
    alwaysSucceedsNoDatum arg =
      case unsafeFromBuiltinData arg of
        PV3.ScriptContext _txInfo (PV3.Redeemer _redeemer) scriptInfo ->
          case scriptInfo of
            -- We fail if this is a spending script with a Datum
            PV3.SpendingScript _ (Just _) -> P.error ()
            _ -> ()
    |]

alwaysSucceedsWithDatumQ :: Q [Dec]
alwaysSucceedsWithDatumQ =
  [d|
    alwaysSucceedsWithDatum :: P.BuiltinData -> ()
    alwaysSucceedsWithDatum arg =
      case unsafeFromBuiltinData arg of
        -- Expecting a spending script with a Datum, thus failing when it is not
        PV3.ScriptContext _txInfo (PV3.Redeemer _redeemer) (PV3.SpendingScript _ (Just _)) -> ()
        _ -> P.error ()
    |]

alwaysFailsNoDatumQ :: Q [Dec]
alwaysFailsNoDatumQ =
  [d|
    alwaysFailsNoDatum :: P.BuiltinData -> ()
    alwaysFailsNoDatum arg =
      case fromBuiltinData arg of
        Just (PV3.ScriptContext _txInfo (PV3.Redeemer _redeemer) scriptInfo) ->
          case scriptInfo of
            -- We fail only if this is not a spending script with a Datum
            PV3.SpendingScript _ (Just _) -> ()
            _ -> P.error ()
        Nothing -> ()
    |]

alwaysFailsWithDatumQ :: Q [Dec]
alwaysFailsWithDatumQ =
  [d|
    alwaysFailsWithDatum :: P.BuiltinData -> ()
    alwaysFailsWithDatum arg =
      case fromBuiltinData arg of
        Just (PV3.ScriptContext _txInfo (PV3.Redeemer _redeemer) scriptInfo) ->
          case scriptInfo of
            -- We fail only if this is a spending script with a Datum
            PV3.SpendingScript _ (Just _) -> P.error ()
            _ -> ()
        Nothing -> ()
    |]

redeemerSameAsDatumQ :: Q [Dec]
redeemerSameAsDatumQ =
  [d|
    redeemerSameAsDatum :: P.BuiltinData -> ()
    redeemerSameAsDatum arg =
      case unsafeFromBuiltinData arg of
        PV3.ScriptContext _txInfo (PV3.Redeemer redeemer) (PV3.SpendingScript _ (Just (PV3.Datum datum))) ->
          -- Expecting a spending script with a Datum, thus failing when it is not
          if datum P.== redeemer then () else P.error ()
        _ -> P.error ()
    |]

evenDatumQ :: Q [Dec]
evenDatumQ =
  [d|
    evenDatum :: P.BuiltinData -> ()
    evenDatum arg =
      case unsafeFromBuiltinData arg of
        PV3.ScriptContext _txInfo _redeemer (PV3.SpendingScript _ (Just (PV3.Datum datum))) ->
          -- Expecting a spending script with a Datum, thus failing when it is not
          if P.modulo (P.unsafeDataAsI datum) 2 P.== 0 then () else P.error ()
    |]

evenRedeemerNoDatumQ :: Q [Dec]
evenRedeemerNoDatumQ =
  [d|
    evenRedeemerNoDatum :: P.BuiltinData -> ()
    evenRedeemerNoDatum arg =
      case unsafeFromBuiltinData arg of
        PV3.ScriptContext _txInfo (PV3.Redeemer redeemer) scriptInfo ->
          case scriptInfo of
            -- Expecting No Datum, therefore should fail when it is supplied
            PV3.SpendingScript _ (Just _) -> P.error ()
            _ -> if P.modulo (P.unsafeDataAsI redeemer) 2 P.== 0 then () else P.error ()
    |]

evenRedeemerWithDatumQ :: Q [Dec]
evenRedeemerWithDatumQ =
  [d|
    evenRedeemerWithDatum :: P.BuiltinData -> ()
    evenRedeemerWithDatum arg =
      case unsafeFromBuiltinData arg of
        PV3.ScriptContext _txInfo (PV3.Redeemer redeemer) (PV3.SpendingScript _ (Just _)) ->
          -- Expecting a spending script with a Datum, thus failing when it is not
          if P.modulo (P.unsafeDataAsI redeemer) 2 P.== 0 then () else P.error ()
        _ -> P.error ()
    |]

purposeIsWellformedNoDatumQ :: Q [Dec]
purposeIsWellformedNoDatumQ =
  [d|
    purposeIsWellformedNoDatum :: P.BuiltinData -> ()
    purposeIsWellformedNoDatum arg =
      case unsafeFromBuiltinData arg of
        PV3.ScriptContext txInfo (PV3.Redeemer _redeemer) scriptInfo ->
          case scriptInfo of
            PV3.MintingScript cs ->
              if PAM.member cs $ PV3.getValue $ PV3.txInfoMint txInfo
                then ()
                else P.error ()
            -- Expecting No Datum, therefore should fail when it is supplied
            PV3.SpendingScript txOutRef mDatum ->
              case mDatum of
                Just _ -> P.error ()
                Nothing ->
                  if null $ P.filter ((txOutRef P.==) . PV3.txInInfoOutRef) $ PV3.txInfoInputs txInfo
                    then P.error ()
                    else ()
            PV3.RewardingScript stakingCredential ->
              if PAM.member stakingCredential $ PV3.txInfoWdrl txInfo
                then ()
                else P.error ()
            PV3.CertifyingScript _idx txCert ->
              if null $ P.filter (txCert P.==) $ PV3.txInfoTxCerts txInfo
                then P.error ()
                else ()
            PV3.VotingScript voter ->
              if PAM.member voter $ PV3.txInfoVotes txInfo
                then ()
                else P.error ()
            PV3.ProposingScript _idx propProc ->
              if null $ P.filter (propProc P.==) $ PV3.txInfoProposalProcedures txInfo
                then P.error ()
                else ()
    |]

purposeIsWellformedWithDatumQ :: Q [Dec]
purposeIsWellformedWithDatumQ =
  [d|
    purposeIsWellformedWithDatum :: P.BuiltinData -> ()
    purposeIsWellformedWithDatum arg =
      case unsafeFromBuiltinData arg of
        PV3.ScriptContext txInfo (PV3.Redeemer _redeemer) (PV3.SpendingScript txOutRef (Just _)) ->
          if null $ P.filter ((txOutRef P.==) . PV3.txInInfoOutRef) $ PV3.txInfoInputs txInfo
            then P.error ()
            else ()
        _ -> P.error ()
    |]

datumIsWellformedQ :: Q [Dec]
datumIsWellformedQ =
  [d|
    datumIsWellformed :: P.BuiltinData -> ()
    datumIsWellformed arg =
      case unsafeFromBuiltinData arg of
        PV3.ScriptContext _txInfo (PV3.Redeemer _redeemer) (PV3.SpendingScript _txOutRef Nothing) -> ()
        PV3.ScriptContext txInfo (PV3.Redeemer _redeemer) (PV3.SpendingScript _txOutRef (Just datum)) ->
          if null $ P.filter (datum P.==) $ PAM.elems $ PV3.txInfoData txInfo
            then P.error ()
            else ()
        _ -> P.error ()
    |]

inputsOutputsAreNotEmptyQ :: Q [Dec]
inputsOutputsAreNotEmptyQ =
  [d|
    inputsOutputsAreNotEmpty :: P.BuiltinData -> ()
    inputsOutputsAreNotEmpty arg =
      case unsafeFromBuiltinData arg of
        PV3.ScriptContext txInfo _redeemer _scriptPurpose ->
          if null (PV3.txInfoInputs txInfo) || null (PV3.txInfoOutputs txInfo)
            then P.error ()
            else ()
    |]
