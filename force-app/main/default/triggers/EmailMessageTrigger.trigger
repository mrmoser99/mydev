trigger EmailMessageTrigger on EmailMessage (before insert, before update) {
    if(trigger.isInsert){
        for(EmailMessage em :Trigger.new){
            System.debug('99999Swapnil Insert ParentId : '+em.ParentId);
            System.debug('99999Swapnil Insert  RelatedToId : '+em.RelatedToId);
            System.debug('99999Swapnil Insert  ToAddress: '+em.ToAddress);
        }
        EmailMessage em1 =Trigger.new[0];
        Case cs = [Select Id, Functional_Email__c FROM Case WHERE Id= :em1.ParentId];
        cs.Functional_Email__c = trigger.new[0].ToAddress;
        Update cs;
    }
    if(trigger.isInsert){
        for(EmailMessage em :Trigger.new){
            System.debug('99999Swapnil Update ParentId : '+em.ParentId);
            System.debug('99999Swapnil Update RelatedToId : '+em.RelatedToId);
        }
    }
}