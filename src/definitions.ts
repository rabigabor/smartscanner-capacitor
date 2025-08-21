export interface SmartScannerPluginMrzOptions {
  action: "START_SCANNER";
  options: {
    mode: 'mrz';
    mrzFormat: any;
    config: {
      background: string;
      branding: boolean;
      isManualCapture: boolean;
      analyzeTime: number;
    };
  };
}
export interface SmartScannerPluginBarcodeOptions {
  action: "START_SCANNER";
  options: {
    mode: 'barcode';
    barcodeOptions: {
      barcodeFormats: 'QR_CODE'[];
    };
    config: {
      background: string;
      branding: boolean;
      isManualCapture: boolean;
    };
  };
}


export interface SmartScannerPluginInterface {
  echo(options: { value: string }): Promise<{ value: string }>;
  executeScanner(options: SmartScannerPluginMrzOptions | SmartScannerPluginBarcodeOptions): Promise<any>;
}
