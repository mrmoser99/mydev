trigger EmailMessageTrigger on EmailMessage (before insert, after insert) {
    
    if(trigger.isBefore){
    System.debug('99999Swapnil Before  EmailTrigger');
        for(EmailMessage em :Trigger.new){
        System.debug('99999Swapnil Before  EmailTrigger: '+em.ValidatedFromAddress );
            if(em.ValidatedFromAddress== 'swapnil.gurav@dllgroup.com'){
                em.FromAddress = 'sngurav@gmail.com';
                em.ValidatedFromAddress = 'sngurav@gmail.com';
                System.debug('99999Swapnil Before  EmailTrigger: '+em.ValidatedFromAddress );
            }
        }
    }
    
    if(trigger.isAfter){
    
        for(EmailMessage em :Trigger.new){
            System.debug('99999Swapnil After  EmailTrigger: '+em.FromAddress);
            System.debug('99999Swapnil After  EmailTrigger: '+em);
            if(em.ValidatedFromAddress== 'swapnil.gurav@dllgroup.com'){
                EmailMessageRelation emr = new EmailMessageRelation();
                emr.RelationAddress = 'sngurav@gmail.com';
                emr.RelationType = 'FromAddress';
                emr.EmailMessageId = em.Id;
                Insert emr;
                //em.FromAddress = 'swapnil.gurav@cc.dllgroup.com';
                //em.ValidatedFromAddress = 'swapnil.gurav@dllgroup.com';
                /*EmailMessage em2 = new EmailMessage();
                em2.id = em.id;
                em2.FromAddress = 'sngurav@gmail.com';
                em2.ValidatedFromAddress = 'sngurav@gmail.com';
                Update em2;*/
                //System.debug('99999Swapnil After  FromAddress: '+em2.FromAddress );
            }
                
        }
        
    }
}