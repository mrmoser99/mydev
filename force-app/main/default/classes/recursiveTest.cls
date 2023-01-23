/**
 * @description       : 
 * @author            : Mark R. Moser
 * @group             : 
 * @last modified on  : 01-20-2023
 * @last modified by  : Mark Moser
 * 
 * this is a recursive class and will run soql per level in a hierarchy. we will normally have 1-4 levels in a dealer hierarchy.  SOQL limits are 100 soql statements; we will never
 * have a dealer hierarchy with 100 levels.  If we get 100 levels, then we should give up on go home.
 * 
 * mark did an amazing job on this!!!!
 * 
 * call this as follows:

    Set<ID> test = new Set<ID>();
    test.add('00178000007a3yB');
    recursiveTest t = new recursiveTest(test);
    system.debug('final parent set is: ' + t.finalParentSet);

**/

public class recursiveTest {
    
        /* holder of final set of parents */
        public Set<ID> finalParentSet = new Set<ID>();

        /*constructor*/
        public recursiveTest(Set<ID> accountSet){
            getChildren(accountSet);
        }

        /* Recursive method returning children of a set of parents) */
   	    public Set<ID> getChildren(Set<ID> accountSet) {

            List<Account> tempList = [select id from account where ParentId in :accountSet];
            Set<ID> childSet = new Set<ID>(); 
            for (Account a:tempList){
                finalParentSet.add(a.id);
                childSet.add(a.id);
            }

            if (tempList.size() == 0){
                return null;
            }
            else{
                return getChildren(childSet);  
            }
        }
    
}

