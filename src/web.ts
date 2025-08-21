import { WebPlugin } from '@capacitor/core';
import type { SmartScannerPluginBarcodeOptions, SmartScannerPluginInterface, SmartScannerPluginMrzOptions } from './definitions';

export class SmartScannerPluginWeb extends WebPlugin implements SmartScannerPluginInterface {
  constructor() {
    super();
  }

  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }

  async executeScanner(options: SmartScannerPluginMrzOptions | SmartScannerPluginBarcodeOptions): Promise<void> {
    console.log('executeScanner', options);
  }
}