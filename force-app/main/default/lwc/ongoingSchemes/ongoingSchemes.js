import { LightningElement, track, wire } from 'lwc';
import UserSpecificPromos from '@salesforce/apex/getUserSpecificPromos.UserSpecificPromos';

export default class OngoingSchemes extends LightningElement {
      @track promos = [];

    @wire(UserSpecificPromos)
    wiredPromos({ error, data }) {
        console.log('OUTPUT : ---data1----',data);
        if (data) {
            console.log('OUTPUT :---data2--- ',data);
            this.promos = data.map(promo => {
                console.log('OUTPUT :---this.promos---- ',this.promos);
                const rawContent = promo.Ongoing_Schemes__c || '';
                console.log('OUTPUT : ---rawContent---',rawContent);

                // Only split when number + dot + space appears at the START of a new line
                const regex = /(?:^|\r?\n)(\d+\.\s)/g;
                const parts = rawContent.split(regex);

                // Recombine parts so numbers like 10.2.3 or section references remain intact
                let result = [];
                for (let i = 1; i < parts.length; i += 2) {
                    const point = parts[i] + (parts[i + 1] || ' ');
                    result.push(point.trim()+ '<br/><br/>');
                }
                console.log('OUTPUT : --result---',result);
               
                return {
                    Id: promo.Id,
                    Region__c: promo.Region__c,
                    Type__c: promo.Type__c,
                    points: result,
                    pointsAsHTML: result.join('') // string with <br/><br/>
                };
            });
             console.log('OUTPUT :--pointsAsHTML-- ',promo.pointsAsHTML);
        } else if (error) {
            console.error('Error fetching promos:', error);
        }
    }
}