trigger creditApplicationOnQuote on Quote (after insert, after update) {
    if (Trigger.isAfter) {
        if(Trigger.isInsert || Trigger.isUpdate) {
            creditApplicationOnQuoteHelper.updateOpportunityByQuote(Trigger.new);
        }
    }
}