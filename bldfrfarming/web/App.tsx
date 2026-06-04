import { useState, useCallback, useEffect } from 'react';
import { isDebug, useNuiEvent, fetchNui } from './hooks/useNui';

interface ProcessingItem {
  label: string;
  inputItem: string;
  inputAmount: number;
  outputItem: string;
  outputAmount: number;
  currentCount: number;
}

interface SellingItem {
  label: string;
  item: string;
  price: number;
  currentCount: number;
}

interface FarmData {
  success: boolean;
  processing: Record<string, ProcessingItem>;
  selling: Record<string, SellingItem>;
  menuType?: string;
  error?: string;
}

const mockData: FarmData = {
  success: true,
  processing: {
    wheat: { label: 'Process Wheat into Flour', inputItem: 'raw_wheat', inputAmount: 5, outputItem: 'flour', outputAmount: 2, currentCount: 25 },
    corn: { label: 'Can Corn', inputItem: 'raw_corn', inputAmount: 3, outputItem: 'canned_corn', outputAmount: 1, currentCount: 12 },
    tomato: { label: 'Make Tomato Sauce', inputItem: 'raw_tomato', inputAmount: 6, outputItem: 'tomato_sauce', outputAmount: 2, currentCount: 30 }
  },
  selling: {
    flour: { label: 'Flour', item: 'flour', price: 50, currentCount: 10 },
    canned_corn: { label: 'Canned Corn', item: 'canned_corn', price: 75, currentCount: 5 },
    tomato_sauce: { label: 'Tomato Sauce', item: 'tomato_sauce', price: 60, currentCount: 8 }
  }
};

type TabType = 'farm' | 'processing' | 'selling' | 'prices';

export default function App() {
  const [visible, setVisible] = useState(isDebug);
  const [activeTab, setActiveTab] = useState<TabType>('farm');
  const [data, setData] = useState<FarmData | null>(null);
  const [loading, setLoading] = useState(false);
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' | 'warning' } | null>(null);

  useNuiEvent('open', (payload: { menuType?: string }) => {
    setVisible(true);
    if (payload?.menuType) {
      setActiveTab(payload.menuType as TabType);
    }
    refreshData();
  });

  useNuiEvent('close', () => setVisible(false));

  const showNotification = useCallback((message: string, type: 'success' | 'error' | 'warning' = 'success') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 3000);
  }, []);

  const refreshData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await fetchNui<FarmData>('refreshData', {}, mockData);
      if (result.success) {
        setData(result);
      } else {
        showNotification(result.error || 'Failed to load data', 'error');
      }
    } catch (e) {
      if (isDebug) setData(mockData);
    }
    setLoading(false);
  }, [showNotification]);

  const handlePickCrop = useCallback(async (cropKey: string) => {
    try {
      const result = await fetchNui<{ success: boolean; amount?: number; item?: string; error?: string }>(
        'pickCrop',
        { cropKey },
        { success: true, amount: 2, item: 'raw_wheat' }
      );
      if (result.success) {
        showNotification(`Picked ${result.amount}x ${result.item}`, 'success');
        refreshData();
      } else {
        showNotification(result.error || 'Failed to pick crop', 'error');
      }
    } catch (e) {
      if (isDebug) showNotification('Picked 2x raw_wheat (debug)', 'success');
    }
  }, [refreshData, showNotification]);

  const handleProcessCrop = useCallback(async (processKey: string, quantity: number) => {
    try {
      const result = await fetchNui<{ success: boolean; processedAmount?: number; outputItem?: string; error?: string }>(
        'processCrop',
        { processKey, quantity },
        { success: true, processedAmount: 2, outputItem: 'flour' }
      );
      if (result.success) {
        showNotification(`Processed ${result.processedAmount}x ${result.outputItem}`, 'success');
        refreshData();
      } else {
        showNotification(result.error || 'Failed to process', 'error');
      }
    } catch (e) {
      if (isDebug) showNotification('Processed 2x flour (debug)', 'success');
    }
  }, [refreshData, showNotification]);

  const handleSellItem = useCallback(async (sellKey: string, quantity: number) => {
    try {
      const result = await fetchNui<{ success: boolean; payout?: number; error?: string }>(
        'sellItem',
        { sellKey, quantity },
        { success: true, payout: 500 }
      );
      if (result.success) {
        showNotification(`Sold for $${result.payout}`, 'success');
        refreshData();
      } else {
        showNotification(result.error || 'Failed to sell', 'error');
      }
    } catch (e) {
      if (isDebug) showNotification('Sold for $500 (debug)', 'success');
    }
  }, [refreshData, showNotification]);

  const handleClose = useCallback(() => {
    setVisible(false);
    fetchNui('close', {}, { success: true });
  }, []);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') handleClose();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [handleClose]);

  useEffect(() => {
    if (visible && isDebug) {
      setData(mockData);
    }
  }, [visible]);

  if (!visible) return null;

  const tabs: { id: TabType; label: string; icon: string }[] = [
    { id: 'farm', label: 'Pick', icon: '🌱' },
    { id: 'processing', label: 'Process', icon: '⚙️' },
    { id: 'selling', label: 'Sell', icon: '💰' },
    { id: 'prices', label: 'Prices', icon: '📊' }
  ];

  return (
    <div className="w-screen h-screen flex items-center justify-center p-4">
      <div className="w-[700px] max-w-full bg-slate-900/95 border border-slate-700 rounded-xl shadow-2xl overflow-hidden">
        <div className="bg-gradient-to-r from-emerald-800 to-green-700 px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="text-2xl">🌾</span>
            <h1 className="text-white text-xl font-bold tracking-wide">Farming Job</h1>
          </div>
          <button
            onClick={handleClose}
            className="text-white/70 hover:text-white transition-colors text-lg leading-none p-1 hover:bg-white/10 rounded"
          >
            ✕
          </button>
        </div>

        <div className="flex border-b border-slate-700 bg-slate-800/50">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex-1 px-4 py-3 text-sm font-medium transition-all ${
                activeTab === tab.id
                  ? 'text-emerald-400 border-b-2 border-emerald-400 bg-slate-800'
                  : 'text-slate-400 hover:text-white hover:bg-slate-700/50'
              }`}
            >
              <span className="mr-2">{tab.icon}</span>
              {tab.label}
            </button>
          ))}
        </div>

        {notification && (
          <div
            className={`mx-6 mt-4 px-4 py-2 rounded-lg text-sm font-medium ${
              notification.type === 'success'
                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                : notification.type === 'warning'
                ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                : 'bg-red-500/20 text-red-400 border border-red-500/30'
            }`}
          >
            {notification.message}
          </div>
        )}

        <div className="p-6 max-h-[400px] overflow-y-auto">
          {loading ? (
            <div className="flex items-center justify-center py-8">
              <div className="w-8 h-8 border-2 border-emerald-400 border-t-transparent rounded-full animate-spin" />
            </div>
          ) : (
            <>
              {activeTab === 'farm' && <FarmTab data={data} onPick={handlePickCrop} />}
              {activeTab === 'processing' && <ProcessingTab data={data} onProcess={handleProcessCrop} />}
              {activeTab === 'selling' && <SellingTab data={data} onSell={handleSellItem} />}
              {activeTab === 'prices' && <PricesTab data={data} />}
            </>
          )}
        </div>
      </div>
    </div>
  );
}

function FarmTab({ data, onPick }: { data: FarmData | null; onPick: (key: string) => void }) {
  const crops = [
    { key: 'wheat', label: 'Wheat', icon: '🌾', item: 'raw_wheat' },
    { key: 'corn', label: 'Corn', icon: '🌽', item: 'raw_corn' },
    { key: 'tomato', label: 'Tomato', icon: '🍅', item: 'raw_tomato' }
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
      {crops.map((crop) => (
        <div
          key={crop.key}
          className="bg-slate-800/60 border border-slate-700 rounded-lg p-4 flex flex-col items-center gap-3"
        >
          <span className="text-4xl">{crop.icon}</span>
          <h3 className="text-white font-semibold">{crop.label}</h3>
          <p className="text-slate-400 text-xs">{crop.item}</p>
          <button
            onClick={() => onPick(crop.key)}
            className="w-full mt-auto px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg font-medium transition-colors"
          >
            Pick
          </button>
        </div>
      ))}
    </div>
  );
}

function ProcessingTab({
  data,
  onProcess
}: {
  data: FarmData | null;
  onProcess: (key: string, quantity: number) => void;
}) {
  const [quantities, setQuantities] = useState<Record<string, number>>({});

  const processingItems = data?.processing || {};

  return (
    <div className="space-y-3">
      {Object.entries(processingItems).map(([key, item]) => (
        <div
          key={key}
          className="bg-slate-800/60 border border-slate-700 rounded-lg p-4 flex items-center gap-4"
        >
          <div className="flex-1">
            <h3 className="text-white font-semibold">{item.label}</h3>
            <p className="text-slate-400 text-sm mt-1">
              Requires: {item.inputAmount}x {item.inputItem} → Produces: {item.outputAmount}x {item.outputItem}
            </p>
            <p className="text-emerald-400 text-sm">
              You have: {item.currentCount}x {item.inputItem}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <input
              type="number"
              min={1}
              max={Math.floor(item.currentCount / item.inputAmount)}
              value={quantities[key] || 1}
              onChange={(e) => setQuantities({ ...quantities, [key]: Math.max(1, parseInt(e.target.value) || 1) })}
              className="w-20 px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white text-center"
            />
            <button
              onClick={() => onProcess(key, quantities[key] || 1)}
              disabled={item.currentCount < item.inputAmount}
              className="px-4 py-2 bg-amber-600 hover:bg-amber-500 disabled:bg-slate-600 disabled:cursor-not-allowed text-white rounded-lg font-medium transition-colors"
            >
              Process
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}

function SellingTab({
  data,
  onSell
}: {
  data: FarmData | null;
  onSell: (key: string, quantity: number) => void;
}) {
  const [quantities, setQuantities] = useState<Record<string, number>>({});

  const sellingItems = data?.selling || {};

  return (
    <div className="space-y-3">
      {Object.entries(sellingItems).map(([key, item]) => (
        <div
          key={key}
          className="bg-slate-800/60 border border-slate-700 rounded-lg p-4 flex items-center gap-4"
        >
          <div className="flex-1">
            <div className="flex items-center gap-2">
              <h3 className="text-white font-semibold">{item.label}</h3>
              <span className="text-emerald-400 font-bold">${item.price}</span>
            </div>
            <p className="text-slate-400 text-sm">You have: {item.currentCount}x</p>
          </div>
          <div className="flex items-center gap-2">
            <input
              type="number"
              min={1}
              max={item.currentCount}
              value={quantities[key] || 1}
              onChange={(e) => setQuantities({ ...quantities, [key]: Math.max(1, parseInt(e.target.value) || 1) })}
              className="w-20 px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white text-center"
            />
            <button
              onClick={() => onSell(key, quantities[key] || 1)}
              disabled={item.currentCount < 1}
              className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 disabled:bg-slate-600 disabled:cursor-not-allowed text-white rounded-lg font-medium transition-colors"
            >
              Sell
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}

function PricesTab({ data }: { data: FarmData | null }) {
  const sellingItems = data?.selling || {};

  const allPrices = [
    { item: 'raw_wheat', label: 'Raw Wheat', price: 'N/A (Process first)', isRaw: true },
    { item: 'raw_corn', label: 'Raw Corn', price: 'N/A (Process first)', isRaw: true },
    { item: 'raw_tomato', label: 'Raw Tomato', price: 'N/A (Process first)', isRaw: true },
    ...Object.entries(sellingItems).map(([key, item]) => ({
      item: item.item,
      label: item.label,
      price: `$${item.price}`,
      isRaw: false
    }))
  ];

  return (
    <div>
      <h3 className="text-white font-semibold mb-4 flex items-center gap-2">
        <span className="text-emerald-400">💰</span> Price List
      </h3>
      <div className="space-y-2">
        {allPrices.map((item) => (
          <div
            key={item.item}
            className={`flex items-center justify-between px-4 py-3 rounded-lg ${
              item.isRaw ? 'bg-slate-800/40 border border-slate-700/50' : 'bg-slate-800/80 border border-slate-700'
            }`}
          >
            <div className="flex items-center gap-3">
              <span className={`font-medium ${item.isRaw ? 'text-slate-400' : 'text-white'}`}>{item.label}</span>
              {item.isRaw && <span className="text-xs text-amber-400 bg-amber-400/10 px-2 py-0.5 rounded">Raw</span>}
            </div>
            <span className={item.isRaw ? 'text-slate-500' : 'text-emerald-400 font-bold'}>{item.price}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
