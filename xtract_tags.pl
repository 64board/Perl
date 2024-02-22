#!/usr/bin/perl
# Extract some FIXML tags data from log file.
# janeiros@mbfcc.com
# 2024-02-16

use strict;
use warnings;

use 5.010;

use feature 'say';

my $rpt_count = 1;

while (<>) {

    chomp;

    # Only XML log lines.
    next if ! /\<FIXML/;

    # Non greedy matching, multiple trade reports
    # in one batch.
    while (/(\<TrdCaptRpt.+?TrdCaptRpt\>)/g) {

        my $trade_report = $1;

        my ($report_id) = $trade_report =~ /RptID=\"([^\"]+)\"/;
        my ($cust_cpcty) = $trade_report =~ /CustCpcty=\"([^\"]+)\"/;
        
        my ($trans_typ) = $trade_report =~ /TransTyp=\"([^\"]+)\"/;
        my ($trd_typ) = $trade_report =~ /TrdTyp=\"([^\"]+)\"/;
        my ($trd_subtyp) = $trade_report =~ /TrdSubTyp=\"([^\"]+)\"/;
        my ($px_typ) = $trade_report =~ /PxTyp=\"([^\"]+)\"/;
        my ($inpt_src) = $trade_report =~ /InptSrc=\"([^\"]+)\"/;
        my ($trd_dt) = $trade_report =~ /TrdDt=\"([^\"]+)\"/;
        my ($symbol) = $trade_report =~ /Instrmt Sym=\"([^\"]+)\"/;
        my ($contract_period) = $trade_report =~ /MMY=\"([^\"]+)\"/;
        my ($sec_typ) = $trade_report =~ /SecTyp=\"([^\"]+)\"/;
        my ($strike_px) = $trade_report =~ /StrkPx=\"([^\"]+)\"/;
        my ($put_call) = $trade_report =~ /PutCall=\"([^\"]+)\"/;
        my ($account) = $trade_report =~ /\<Pty ID=\"([^\"]+)\" Src=\"C\" R=\"24\"\>/;
        my ($side) = $trade_report =~ /Side=\"([^\"]+)\"/;
        my ($qty) = $trade_report =~ /LastQty=\"([^\"]+)\"/;
        my ($price) = $trade_report =~ /LastPx=\"([^\"]+)\"/;
        my ($txn_time) = $trade_report =~ /TxnTm=\"([^\"]+)\"/;
        my ($exchange) = $trade_report =~ /\<Pty ID=\"([^\"]+)\" Src=\"C\" R=\"22\"\>/;
        my ($exec_id) = $trade_report =~ /ExecID=\"([^\"]+)\"/;

        # Optional tags.
        $trd_subtyp //= 'null';
        $strike_px //= 'null';
        $put_call //= 'null';

        say sprintf "%s. rptID=%s custCpcty=%s transTyp=%s trdTyp=%s trdSubtyp=%s PxTyp=%s inputSrc=%s "
            . "date=%s symbol=%s contractPeriod=%s securityTyp=%s StrkPx=%s putCall=%s "
            . "acct=%s side=%s qty=%s px=%s txnTime=%s exch=%s trdID=%s",
            $rpt_count, $report_id, $cust_cpcty, $trans_typ, $trd_typ, $trd_subtyp, $px_typ, $inpt_src, $trd_dt,
            $symbol, $contract_period, $sec_typ, $strike_px, $put_call, $account, $side,
            $qty, $price, $txn_time, $exchange, $exec_id;

        $count++;
    }

}

__END__