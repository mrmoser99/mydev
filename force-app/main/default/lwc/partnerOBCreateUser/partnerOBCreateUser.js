import { LightningElement, api,track} from 'lwc';

const columns = [
    { label: 'FirstName', fieldName: 'FirstName', type:'text'},
    { label: 'LastName', fieldName: 'LastName',type:'text' },
    { label: 'Email', fieldName: 'Email',type:'text' },
    { label: 'Location', fieldName: 'Location',type:'text' },
    { label: 'Role', fieldName: 'Role',type:'text' }
    
];



export default class partnerOBCreateUser extends LightningElement {

@api tddata;
@api profileName;
@track columns = columns;
strProfile = '';
get options() {
    return [
        { label: 'Partner Admin', value: 'Partner Admin' }
       
    ];
}

selectProfile(event){
    this.strProfile = event.target.value;
}

@api 
getProfileName(){
    return this.strProfile;
}


}