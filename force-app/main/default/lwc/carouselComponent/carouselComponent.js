import { LightningElement, track, wire } from 'lwc';
import getImageBase64 from '@salesforce/apex/PromoContentController.getImageBase64';

export default class ImageCarousel extends LightningElement {
    @track imageUrls = [];
    currentIndex = 0;
    trackStyle = 'transform: translateX(0%)';
    intervalId;

    @wire(getImageBase64)
    wiredImages({ error, data }) {
        if (data && data.length > 0) {
            this.imageUrls = data;
            console.log('this.imageUrls'+this.imageUrls);
            this.startCarousel();
        } else if (error) {
            console.error('Error loading images', error);
        }
    }

    startCarousel() {
        // Clear previous interval if already running
        if (this.intervalId) {
            clearInterval(this.intervalId);
        }

        this.intervalId = setInterval(() => {
            this.currentIndex = (this.currentIndex + 1) % this.imageUrls.length;
            this.trackStyle = `transform: translateX(-${this.currentIndex * 100}%);`;
        }, 2500); // 2.5 seconds between slides
    }

    disconnectedCallback() {
        // Prevent memory leaks
        clearInterval(this.intervalId);
    }
}