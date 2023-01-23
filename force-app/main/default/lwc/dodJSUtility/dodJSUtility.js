import check from '@salesforce/apex/permissionUtility.check';



function checkPermission (pName) {

    //call an apex class to check for userid/permission existence
        
    let myResult = null;
    
    check({ permissionName : pName})  //call apex and tell me true or false
    .then(result => {
        this.myResult = result;
    })
    .catch(err => {
        console.log('Error in check '  + JSON.stringify(err));
    })
    
    return new Promise(resolve => {
        setTimeout(() => {
            resolve(this.myResult);
        },1500);
    });

        
}



export {checkPermission};