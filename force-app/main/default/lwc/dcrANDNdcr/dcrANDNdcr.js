// productSelector.js
import { LightningElement, track } from 'lwc';

const PRODUCTS = [
    { label: 'MonoPERC Monofacial M10', value: 'MonoPERC Monofacial M10', type: ['DCR', 'NDCR'], category: 'Mono' },
    { label: 'MonoPERC Bi TBS -M10', value: 'MonoPERC Bi TBS -M10', type: ['DCR', 'NDCR'], category: 'Mono' },
    { label: 'MonoPERC Bi G2G-M10', value: 'MonoPERC Bi G2G-M10', type: ['DCR', 'NDCR'], category: 'Mono' },
    { label: 'TOPCON Bi G2G-M10', value: 'TOPCON Bi G2G-M10', type: ['NDCR'], category: 'TopCon M10' },
    { label: 'TOPCON Bi G2G-M10+', value: 'TOPCON Bi G2G-M10+', type: ['NDCR'], category: 'TopCon M10' },
    { label: 'TOPCON Bi G2G-G12R', value: 'TOPCON Bi G2G-G12R', type: ['DCR', 'NDCR'], category: 'TopCon G12R' },
    { label: 'TOPCON Bi G2G-G12', value: 'TOPCON Bi G2G-G12', type: ['NDCR'], category: 'TopCon G12' }
];

const WATTAGES = {
    'Mono': [550, 545, 540, 535, 530, 525],
    'TopCon M10': [595, 590, 585, 580, 575, 570],
    'TopCon G12R': [630, 625, 620, 615, 610, 605, 600],
    'TopCon G12': [730, 725, 720, 715, 710, 705, 700]
};

export default class dcrANDNdcr extends LightningElement {
    @track selectedType = '';
    @track selectedProduct = '';
    @track selectedWattage = '';

    typeOptions = [
        { label: 'DCR', value: 'DCR' },
        { label: 'NDCR', value: 'NDCR' }
    ];

    get filteredProducts() {
        if (!this.selectedType) return [];
        return PRODUCTS.filter(product => 
            product.type.includes(this.selectedType)
        ).map(product => ({
            label: product.label,
            value: product.value
        }));
    }

    

    get filteredWattages() {
        if (!this.selectedProduct) return [];
        
        const selectedProduct = PRODUCTS.find(p => p.value === this.selectedProduct);
        if (!selectedProduct) return [];
        
        return WATTAGES[selectedProduct.category].map(wattage => ({
            label: wattage.toString(),
            value: wattage.toString()
        }));
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.selectedProduct = '';
        this.selectedWattage = '';
    }

    handleProductChange(event) {
        this.selectedProduct = event.detail.value;
        this.selectedWattage = '';
    }
}