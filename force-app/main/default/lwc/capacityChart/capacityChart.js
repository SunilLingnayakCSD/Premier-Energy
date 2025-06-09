import { LightningElement, track } from 'lwc';
import getCapacityData from '@salesforce/apex/CapacityChartController.getCapacityData';

export default class CapacityChart extends LightningElement {
    @track chartData = [];
    error;

    connectedCallback() {
        getCapacityData()
            .then(result => {
                console.log('Raw result:', JSON.stringify(result));
                this.chartData = result.map(item => {
                    const percentage = item.target > 0 ? (item.achieved / item.target) * 100 : 0;
                    return {
                        key: `${item.entity}-${item.plant}`,
                        entity: item.entity,
                        plant: item.plant,
                        achieved: item.achieved,
                        target: item.target,
                        achievedStyle: `width: ${percentage}%; background-color: #0070d2;`,
                        remainingStyle: `width: ${100 - percentage}%; background-color: #ccc;`
                    };
                });
                console.log('Processed chartData:', this.chartData);
            })
            .catch(error => {
                this.error = 'Failed to load chart data';
                console.error('Error:', error);
            });
    }
}