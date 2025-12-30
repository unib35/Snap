import React, { useState, useEffect, useRef } from 'react';
import { 
  X, MousePointer2, Music, Grid, Keyboard as KeyboardIcon, 
  Settings, Power, MoreHorizontal, Volume2, SkipBack, Play, Pause, SkipForward,
  Monitor, Command, Search, Sun, Moon, Battery, Wifi,
  Tv, ChevronUp, ChevronDown, ChevronLeft, ChevronRight, 
  CornerUpLeft, AppWindow, Globe, Terminal, Folder,
  Youtube, Plus, Crosshair, MousePointerClick, Laptop, Smartphone, Scan, RefreshCw, CheckCircle2,
  ArrowRight, QrCode, Hash, CornerDownLeft, Delete, ArrowUp, Mic
} from 'lucide-react';

interface RemoteAppProps {
  onExit: () => void;
}

interface Device {
  id: string;
  name: string;
  type: 'mac' | 'windows' | 'tv' | 'linux';
  lastConnected?: string;
  ip?: string;
}

const RemoteApp: React.FC<RemoteAppProps> = ({ onExit }) => {
  // Connection State
  const [connectionStatus, setConnectionStatus] = useState<'selecting' | 'connecting' | 'connected'>('selecting');
  const [selectedDevice, setSelectedDevice] = useState<Device | null>(null);
  const [isScanning, setIsScanning] = useState(true);

  // Remote App State
  const [activeTab, setActiveTab] = useState<'remote' | 'touch' | 'media' | 'apps'>('remote');
  const [inputMode, setInputMode] = useState<'trackpad' | 'laser'>('trackpad');
  const [volume, setVolume] = useState(60);
  const [isPlaying, setIsPlaying] = useState(false);
  const [touchPos, setTouchPos] = useState({ x: 0, y: 0 });
  const [isTouching, setIsTouching] = useState(false);
  const [isLaserActive, setIsLaserActive] = useState(false);
  const [isSiriActive, setIsSiriActive] = useState(false);

  // Keyboard State
  const [isKeyboardOpen, setIsKeyboardOpen] = useState(false);
  const [isVoiceTyping, setIsVoiceTyping] = useState(false);
  const [typedText, setTypedText] = useState('');
  const textInputRef = useRef<HTMLTextAreaElement>(null);

  // Status Bar Clock
  const [time, setTime] = useState(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
  useEffect(() => {
    const timer = setInterval(() => setTime(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })), 1000);
    return () => clearInterval(timer);
  }, []);

  // Focus input when keyboard opens
  useEffect(() => {
    if (isKeyboardOpen && textInputRef.current) {
        textInputRef.current.focus();
    }
  }, [isKeyboardOpen]);

  // Handle Voice Typing Simulation
  const toggleVoiceTyping = () => {
    if (isVoiceTyping) {
        setIsVoiceTyping(false);
    } else {
        setIsVoiceTyping(true);
        // Simulate listening and typing
        setTimeout(() => {
            setTypedText(prev => prev + (prev ? ' ' : '') + "Hello, this is voice typing...");
            setIsVoiceTyping(false);
            if (textInputRef.current) textInputRef.current.focus();
        }, 2000);
    }
  };

  // Mock Data
  const recentDevices: Device[] = [
    { id: '1', name: "MacBook Pro M3", type: 'mac', lastConnected: '2 hours ago' },
    { id: '2', name: "Living Room TV", type: 'tv', lastConnected: 'Yesterday' }
  ];

  const nearbyDevices: Device[] = [
    { id: '3', name: "Mac Studio", type: 'mac', ip: "192.168.0.14" }
  ];

  const handleConnect = (device: Device) => {
    setSelectedDevice(device);
    setConnectionStatus('connecting');
    // Simulate connection delay
    setTimeout(() => {
      setConnectionStatus('connected');
    }, 1500);
  };

  const handleTouchStart = (e: React.TouchEvent | React.MouseEvent) => setIsTouching(true);
  const handleTouchEnd = () => setIsTouching(false);
  const handleTouchMove = (e: React.MouseEvent) => {
    if (!isTouching) return;
    setTouchPos({ x: e.movementX, y: e.movementY });
  };

  // --- RENDER: Device Selection Screen ---
  if (connectionStatus === 'selecting') {
    return (
      <div className="fixed inset-0 bg-black text-white z-[100] flex flex-col font-sans overflow-hidden animate-fade-in-up">
        {/* Status Bar */}
        <div className="px-6 py-2 flex justify-between items-center text-xs font-medium z-50">
          <span>{time}</span>
          <div className="flex items-center gap-2">
            <Wifi className="w-4 h-4" />
            <Battery className="w-4 h-4" />
          </div>
        </div>

        {/* Header */}
        <div className="px-6 py-6 flex items-center justify-between">
            <div>
                <h1 className="text-2xl font-bold">Connect</h1>
                <p className="text-gray-500 text-xs mt-1">Select a device to control</p>
            </div>
            <button onClick={onExit} className="p-2 bg-neutral-800 rounded-full hover:bg-neutral-700 transition-colors">
                <X className="w-5 h-5 text-gray-400" />
            </button>
        </div>

        <div className="flex-1 overflow-y-auto px-6 pb-10">
            
            {/* Manual Connection Options (QR & PIN) */}
            <div className="grid grid-cols-2 gap-4 mb-8">
                <button className="flex flex-col items-center justify-center gap-3 p-6 bg-neutral-900/50 border border-white/10 rounded-3xl hover:bg-neutral-800 active:scale-95 transition-all group">
                    <div className="w-16 h-16 rounded-full bg-blue-600/10 flex items-center justify-center group-hover:bg-blue-600/20 transition-colors border border-blue-500/10">
                        <QrCode className="w-7 h-7 text-blue-500" />
                    </div>
                    <span className="font-semibold text-sm text-gray-200">Scan QR</span>
                </button>
                <button className="flex flex-col items-center justify-center gap-3 p-6 bg-neutral-900/50 border border-white/10 rounded-3xl hover:bg-neutral-800 active:scale-95 transition-all group">
                     <div className="w-16 h-16 rounded-full bg-purple-600/10 flex items-center justify-center group-hover:bg-purple-600/20 transition-colors border border-purple-500/10">
                        <Hash className="w-7 h-7 text-purple-500" />
                    </div>
                    <span className="font-semibold text-sm text-gray-200">Enter PIN</span>
                </button>
            </div>

            {/* Nearby Devices (Found) */}
            <div className="mb-8">
                <div className="flex items-center justify-between mb-4">
                    <h3 className="text-sm font-bold text-gray-500 uppercase tracking-wider">Nearby</h3>
                    {/* Compact Scanning Indicator */}
                    <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-neutral-900 border border-white/5">
                        <div className="relative flex h-2 w-2">
                          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                          <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
                        </div>
                        <span className="text-[10px] font-medium text-gray-400">Scanning...</span>
                    </div>
                </div>
                <div className="space-y-3">
                    {nearbyDevices.map(device => (
                        <button 
                            key={device.id}
                            onClick={() => handleConnect(device)}
                            className="w-full p-4 bg-neutral-900/50 border border-white/10 rounded-2xl flex items-center justify-between group hover:bg-neutral-800 active:scale-95 transition-all"
                        >
                            <div className="flex items-center gap-4">
                                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-neutral-800 to-neutral-900 flex items-center justify-center text-white border border-white/5">
                                    <Monitor className="w-6 h-6" />
                                </div>
                                <div className="text-left">
                                    <div className="font-bold text-white">{device.name}</div>
                                    <div className="text-xs text-green-500 flex items-center gap-1">
                                        Found via Wi-Fi
                                    </div>
                                </div>
                            </div>
                            <div className="w-8 h-8 rounded-full bg-white/5 flex items-center justify-center group-hover:bg-blue-600 group-hover:text-white transition-colors">
                                <ArrowRight className="w-4 h-4" />
                            </div>
                        </button>
                    ))}
                </div>
            </div>

            {/* Recent Devices */}
            <div>
                <h3 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4">Recent</h3>
                <div className="space-y-3">
                    {recentDevices.map(device => (
                        <button 
                            key={device.id}
                            onClick={() => handleConnect(device)}
                            className="w-full p-4 bg-neutral-900/30 border border-white/5 rounded-2xl flex items-center justify-between group hover:bg-neutral-800 active:scale-95 transition-all"
                        >
                            <div className="flex items-center gap-4">
                                <div className="w-12 h-12 rounded-full bg-neutral-800 flex items-center justify-center text-gray-400 group-hover:text-white transition-colors">
                                    {device.type === 'tv' ? <Tv className="w-6 h-6" /> : <Laptop className="w-6 h-6" />}
                                </div>
                                <div className="text-left">
                                    <div className="font-bold text-gray-300 group-hover:text-white transition-colors">{device.name}</div>
                                    <div className="text-xs text-gray-600">Last connected: {device.lastConnected}</div>
                                </div>
                            </div>
                        </button>
                    ))}
                </div>
            </div>
        </div>
      </div>
    );
  }

  // --- RENDER: Connecting Screen ---
  if (connectionStatus === 'connecting') {
     return (
        <div className="fixed inset-0 bg-black text-white z-[100] flex flex-col items-center justify-center font-sans overflow-hidden animate-fade-in-up">
            <div className="relative mb-8">
                 <div className="w-20 h-20 border-4 border-blue-600/30 border-t-blue-500 rounded-full animate-spin"></div>
                 <div className="absolute inset-0 flex items-center justify-center">
                    <Wifi className="w-8 h-8 text-blue-500" />
                 </div>
            </div>
            <h2 className="text-xl font-bold mb-2">Connecting to {selectedDevice?.name}...</h2>
            <p className="text-gray-500 text-sm">Securing connection via TLS 1.3</p>
        </div>
     );
  }

  // --- RENDER: Keyboard View (Overlay) ---
  if (isKeyboardOpen) {
    return (
        <div className="fixed inset-0 bg-neutral-900 text-white z-[200] flex flex-col animate-fade-in-up">
            {/* Keyboard Header */}
            <div className="px-4 py-4 flex items-center justify-between bg-neutral-900 border-b border-white/10">
                <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center">
                        <KeyboardIcon className="w-5 h-5" />
                    </div>
                    <div>
                        <h3 className="font-bold text-sm">Keyboard Bridge</h3>
                        <p className="text-[10px] text-green-500">Live Input Active</p>
                    </div>
                </div>
                <div className="flex items-center gap-3">
                     {/* Voice Typing Button */}
                    <button 
                        onClick={toggleVoiceTyping}
                        className={`p-2 rounded-full transition-all ${isVoiceTyping ? 'bg-red-500 text-white animate-pulse' : 'bg-white/10 text-gray-400 hover:text-white'}`}
                    >
                        <Mic className="w-4 h-4" />
                    </button>
                    <button 
                        onClick={() => setIsKeyboardOpen(false)}
                        className="px-4 py-1.5 rounded-full bg-white/10 hover:bg-white/20 text-xs font-bold transition-colors"
                    >
                        Done
                    </button>
                </div>
            </div>

            {/* Input Area (Visual + Functional) */}
            <div className="flex-1 p-4 relative">
                {isVoiceTyping && (
                    <div className="absolute inset-0 flex items-center justify-center z-10 pointer-events-none">
                        <div className="flex gap-1 items-end h-12">
                             <div className="w-1.5 bg-red-500 rounded-full animate-[bounce_1s_infinite] h-6"></div>
                             <div className="w-1.5 bg-red-500 rounded-full animate-[bounce_1.2s_infinite] h-10"></div>
                             <div className="w-1.5 bg-red-500 rounded-full animate-[bounce_0.8s_infinite] h-8"></div>
                             <div className="w-1.5 bg-red-500 rounded-full animate-[bounce_1.1s_infinite] h-12"></div>
                             <div className="w-1.5 bg-red-500 rounded-full animate-[bounce_0.9s_infinite] h-7"></div>
                        </div>
                    </div>
                )}
                <textarea
                    ref={textInputRef}
                    value={typedText}
                    onChange={(e) => setTypedText(e.target.value)}
                    placeholder={isVoiceTyping ? "Listening..." : "Type here to send to Mac..."}
                    className="w-full h-full bg-transparent text-xl leading-relaxed outline-none resize-none placeholder:text-neutral-700 font-mono relative z-0"
                    spellCheck={false}
                />
            </div>

            {/* Accessory View (Modifier Keys) */}
            <div className="bg-neutral-800 border-t border-white/5 p-2 pb-6">
                <div className="flex gap-2 overflow-x-auto no-scrollbar pb-2">
                    {/* Escape */}
                    <button className="h-10 px-4 min-w-[60px] rounded-lg bg-neutral-700 shadow border border-white/5 active:scale-95 active:bg-neutral-600 flex items-center justify-center text-xs font-bold text-gray-300 shrink-0">
                        esc
                    </button>
                    
                    {/* Tab */}
                    <button className="h-10 px-4 min-w-[60px] rounded-lg bg-neutral-700 shadow border border-white/5 active:scale-95 active:bg-neutral-600 flex items-center justify-center text-xs font-bold text-gray-300 shrink-0">
                        tab
                    </button>

                    {/* Control */}
                    <button className="h-10 px-4 min-w-[60px] rounded-lg bg-neutral-700 shadow border border-white/5 active:scale-95 active:bg-neutral-600 flex items-center justify-center text-xs font-bold text-gray-300 shrink-0">
                        ctrl
                    </button>

                    {/* Option */}
                    <button className="h-10 px-4 min-w-[60px] rounded-lg bg-neutral-700 shadow border border-white/5 active:scale-95 active:bg-neutral-600 flex items-center justify-center text-xs font-bold text-gray-300 shrink-0">
                        opt
                    </button>

                    {/* Command */}
                    <button className="h-10 px-4 min-w-[60px] rounded-lg bg-neutral-700 shadow border border-white/5 active:scale-95 active:bg-neutral-600 flex items-center justify-center text-xs font-bold text-gray-300 shrink-0 gap-1">
                        <Command className="w-3 h-3" /> cmd
                    </button>

                     {/* Arrows */}
                    <div className="flex gap-1 ml-2 shrink-0">
                        <button className="h-10 w-12 rounded-lg bg-neutral-600/50 border border-white/5 active:bg-blue-600 active:text-white flex items-center justify-center">
                            <ChevronLeft className="w-5 h-5" />
                        </button>
                         <div className="flex flex-col gap-1">
                            <button className="h-[18px] w-12 rounded bg-neutral-600/50 border border-white/5 active:bg-blue-600 active:text-white flex items-center justify-center">
                                <ArrowUp className="w-3 h-3" />
                            </button>
                            <button className="h-[18px] w-12 rounded bg-neutral-600/50 border border-white/5 active:bg-blue-600 active:text-white flex items-center justify-center">
                                <ChevronDown className="w-3 h-3" />
                            </button>
                         </div>
                        <button className="h-10 w-12 rounded-lg bg-neutral-600/50 border border-white/5 active:bg-blue-600 active:text-white flex items-center justify-center">
                            <ChevronRight className="w-5 h-5" />
                        </button>
                    </div>

                    {/* Enter/Return */}
                     <button className="h-10 px-4 min-w-[60px] rounded-lg bg-neutral-700 shadow border border-white/5 active:scale-95 active:bg-neutral-600 flex items-center justify-center text-xs font-bold text-gray-300 shrink-0 ml-2">
                        <CornerDownLeft className="w-4 h-4" />
                    </button>
                </div>
            </div>
        </div>
    );
  }

  // --- RENDER: Main Remote Interface (Connected) ---
  return (
    <div className="fixed inset-0 bg-black text-white z-[100] flex flex-col font-sans overflow-hidden animate-fade-in-up">
      {/* iOS-style Status Bar */}
      <div className="px-6 py-2 flex justify-between items-center text-xs font-medium z-50">
        <span>{time}</span>
        <div className="flex items-center gap-2">
          <Wifi className="w-4 h-4" />
          <Battery className="w-4 h-4" />
        </div>
      </div>

      {/* App Header - Dynamic Device Name */}
      <div className="px-4 py-4 flex items-center justify-between border-b border-white/5 bg-white/5 backdrop-blur-xl z-50">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center shadow-lg shadow-blue-900/50">
            {selectedDevice?.type === 'tv' ? <Tv className="w-5 h-5 text-white" /> : <Monitor className="w-5 h-5 text-white" />}
          </div>
          <div>
            <h2 className="font-bold text-sm leading-tight">{selectedDevice?.name || 'Mac Studio'}</h2>
            <div className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
              <span className="text-xs text-green-500 font-medium">Connected</span>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button className="p-2 rounded-full hover:bg-white/10 transition-colors">
            <Settings className="w-5 h-5 text-gray-400" />
          </button>
          <button onClick={onExit} className="p-2 rounded-full bg-white/10 hover:bg-white/20 transition-colors text-xs font-bold px-4">
            Exit
          </button>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 relative overflow-hidden bg-gradient-to-b from-neutral-900 to-black">
        
        {/* TAB: REMOTE (Smart TV Style) */}
        {activeTab === 'remote' && (
          <div className="absolute inset-0 flex flex-col items-center justify-center p-6 space-y-6 animate-fade-in-up">
             
             {/* D-Pad Container */}
             <div className="relative w-64 h-64 shrink-0">
                {/* Background Ring */}
                <div className="absolute inset-0 rounded-full bg-neutral-800 border border-white/5 shadow-2xl"></div>
                
                {/* D-Pad Buttons */}
                <button className="absolute top-2 left-1/2 -translate-x-1/2 w-16 h-12 flex items-center justify-center text-white/70 hover:text-white active:scale-95 transition-all">
                  <ChevronUp className="w-8 h-8" />
                </button>
                <button className="absolute bottom-2 left-1/2 -translate-x-1/2 w-16 h-12 flex items-center justify-center text-white/70 hover:text-white active:scale-95 transition-all">
                  <ChevronDown className="w-8 h-8" />
                </button>
                <button className="absolute left-2 top-1/2 -translate-y-1/2 w-12 h-16 flex items-center justify-center text-white/70 hover:text-white active:scale-95 transition-all">
                  <ChevronLeft className="w-8 h-8" />
                </button>
                <button className="absolute right-2 top-1/2 -translate-y-1/2 w-12 h-16 flex items-center justify-center text-white/70 hover:text-white active:scale-95 transition-all">
                  <ChevronRight className="w-8 h-8" />
                </button>

                {/* Center OK Button */}
                <button className="absolute inset-0 m-auto w-24 h-24 rounded-full bg-neutral-700 shadow-inner border border-white/5 flex items-center justify-center active:scale-95 transition-all active:bg-neutral-600">
                  <span className="font-bold text-lg tracking-widest text-white/90">OK</span>
                </button>
             </div>

             {/* Action Row */}
             <div className="flex justify-between w-64 shrink-0">
                <button className="flex flex-col items-center gap-2 group active:scale-95 transition-transform">
                  <div className="w-14 h-14 rounded-2xl bg-neutral-800 border border-white/5 flex items-center justify-center group-hover:bg-neutral-700 transition-colors">
                    <CornerUpLeft className="w-6 h-6 text-gray-400 group-hover:text-white" />
                  </div>
                  <span className="text-xs font-bold text-gray-500">Back</span>
                </button>
                
                <button className="flex flex-col items-center gap-2 group active:scale-95 transition-transform">
                   <div className="w-14 h-14 rounded-2xl bg-neutral-800 border border-white/5 flex items-center justify-center group-hover:bg-neutral-700 transition-colors">
                    <AppWindow className="w-6 h-6 text-gray-400 group-hover:text-white" />
                  </div>
                  <span className="text-xs font-bold text-gray-500">Home</span>
                </button>

                 <button 
                    onClick={() => setIsKeyboardOpen(true)}
                    className="flex flex-col items-center gap-2 group active:scale-95 transition-transform"
                 >
                   <div className="w-14 h-14 rounded-2xl bg-neutral-800 border border-white/5 flex items-center justify-center group-hover:bg-neutral-700 transition-colors">
                    <KeyboardIcon className="w-6 h-6 text-gray-400 group-hover:text-white" />
                  </div>
                  <span className="text-xs font-bold text-gray-500">Keybd</span>
                </button>
             </div>

             {/* Siri / Voice Assistant Button */}
             <div className="w-64 flex justify-center shrink-0">
                 <button 
                    onTouchStart={() => setIsSiriActive(true)}
                    onTouchEnd={() => setIsSiriActive(false)}
                    onMouseDown={() => setIsSiriActive(true)}
                    onMouseUp={() => setIsSiriActive(false)}
                    onMouseLeave={() => setIsSiriActive(false)}
                    className="relative w-16 h-16 rounded-full bg-gradient-to-br from-neutral-800 to-neutral-900 border border-white/10 flex items-center justify-center shadow-lg active:scale-95 transition-transform group overflow-hidden"
                 >
                    {isSiriActive && (
                        <div className="absolute inset-0 bg-gradient-to-br from-blue-600/50 via-purple-600/50 to-pink-600/50 animate-pulse"></div>
                    )}
                    <Mic className={`w-6 h-6 relative z-10 transition-colors ${isSiriActive ? 'text-white' : 'text-gray-400 group-hover:text-white'}`} />
                 </button>
             </div>

             {/* Volume Rocker */}
             <div className="w-64 h-16 bg-neutral-800 rounded-2xl border border-white/5 flex items-center overflow-hidden shrink-0">
                <button 
                  onClick={() => setVolume(Math.max(0, volume - 10))}
                  className="h-full px-6 hover:bg-white/5 active:bg-white/10 transition-colors flex items-center justify-center"
                >
                  <span className="text-xl font-bold text-gray-400">-</span>
                </button>
                <div className="flex-1 flex flex-col items-center justify-center gap-1 border-x border-white/5 h-full bg-neutral-800/50">
                   <Volume2 className="w-4 h-4 text-gray-400" />
                   <span className="text-xs font-mono text-blue-500">{volume}%</span>
                </div>
                 <button 
                  onClick={() => setVolume(Math.min(100, volume + 10))}
                  className="h-full px-6 hover:bg-white/5 active:bg-white/10 transition-colors flex items-center justify-center"
                >
                  <span className="text-xl font-bold text-gray-400">+</span>
                </button>
             </div>

             {/* Siri Visual Overlay */}
             {isSiriActive && (
                 <div className="absolute bottom-4 left-1/2 -translate-x-1/2 pointer-events-none z-50 flex items-end justify-center">
                    <div className="w-64 h-24 bg-gradient-to-t from-blue-500/30 via-purple-500/20 to-transparent blur-3xl rounded-full animate-pulse"></div>
                    <div className="absolute bottom-0 w-20 h-20 bg-white/20 blur-xl rounded-full"></div>
                 </div>
             )}
          </div>
        )}

        {/* TAB: TOUCHPAD / LASER */}
        {activeTab === 'touch' && (
          <div className="absolute inset-0 flex flex-col p-4 animate-fade-in-up">
            {/* Input Mode Toggle */}
            <div className="flex bg-neutral-800 rounded-xl p-1 mb-4 border border-white/5 shrink-0 relative z-20">
                <button
                onClick={() => setInputMode('trackpad')}
                className={`flex-1 py-2 rounded-lg text-xs font-bold transition-all ${inputMode === 'trackpad' ? 'bg-neutral-700 text-white shadow' : 'text-gray-500 hover:text-gray-300'}`}
                >
                Trackpad
                </button>
                <button
                onClick={() => setInputMode('laser')}
                className={`flex-1 py-2 rounded-lg text-xs font-bold transition-all flex items-center justify-center gap-2 ${inputMode === 'laser' ? 'bg-red-900/50 text-red-100 shadow border border-red-500/20' : 'text-gray-500 hover:text-gray-300'}`}
                >
                <Crosshair className="w-3 h-3" /> Laser
                </button>
            </div>

            {inputMode === 'trackpad' ? (
                // Trackpad UI
                <>
                <div 
                    className="flex-1 rounded-3xl bg-neutral-800/50 border border-white/5 relative overflow-hidden group active:bg-neutral-800/80 transition-colors cursor-none touch-none"
                    onMouseDown={handleTouchStart}
                    onMouseUp={handleTouchEnd}
                    onMouseLeave={handleTouchEnd}
                    onMouseMove={handleTouchMove}
                >
                    <div className="absolute inset-0 flex items-center justify-center pointer-events-none opacity-20">
                        <div className="w-32 h-32 rounded-full border border-white/10 animate-ping"></div>
                    </div>
                    <div className="absolute inset-0 flex items-center justify-center">
                        <span className="text-white/10 text-4xl font-black tracking-widest pointer-events-none select-none">TRACKPAD</span>
                    </div>
                    <div className="absolute bottom-8 left-0 right-0 flex justify-center gap-2 px-8">
                        <button className="flex-1 h-16 rounded-2xl bg-white/5 hover:bg-white/10 active:scale-95 transition-all border border-white/5 flex items-center justify-center text-xs font-bold text-gray-400">L</button>
                        <button className="flex-1 h-16 rounded-2xl bg-white/5 hover:bg-white/10 active:scale-95 transition-all border border-white/5 flex items-center justify-center text-xs font-bold text-gray-400">R</button>
                    </div>
                    
                    {/* Visual Feedback Dot */}
                    {isTouching && (
                        <div className="absolute w-12 h-12 bg-white/20 rounded-full blur-xl pointer-events-none transform -translate-x-1/2 -translate-y-1/2" 
                            style={{ left: '50%', top: '50%', transform: `translate(calc(-50% + ${touchPos.x * 2}px), calc(-50% + ${touchPos.y * 2}px))` }} 
                        />
                    )}
                </div>
                </>
            ) : (
                // Laser UI - Enhanced
                <div className="flex-1 flex flex-col items-center justify-center animate-fade-in-up gap-2 min-h-0">
                    {/* Gyro Activation Area */}
                    <div className="flex-1 w-full max-h-[350px] rounded-3xl bg-neutral-800/20 border border-white/5 flex flex-col items-center justify-center relative min-h-0 overflow-hidden">
                         <div className="absolute top-4 left-0 right-0 text-center text-gray-500 text-[10px] font-bold uppercase tracking-wider z-10">Gyro Control</div>
                         
                        <div className="relative flex items-center justify-center">
                            {isLaserActive && (
                                <div className="absolute inset-0 bg-red-600/20 rounded-full blur-3xl animate-pulse"></div>
                            )}
                            <button 
                            onMouseDown={() => setIsLaserActive(true)}
                            onMouseUp={() => setIsLaserActive(false)}
                            onMouseLeave={() => setIsLaserActive(false)}
                            onTouchStart={() => setIsLaserActive(true)}
                            onTouchEnd={() => setIsLaserActive(false)}
                            className={`w-40 h-40 sm:w-56 sm:h-56 rounded-full border-2 flex flex-col items-center justify-center shadow-2xl transition-all duration-200 ${
                                isLaserActive 
                                ? 'bg-red-600 border-red-400 scale-95 shadow-[0_0_50px_rgba(220,38,38,0.5)]' 
                                : 'bg-gradient-to-br from-neutral-800 to-neutral-900 border-white/10'
                            }`}
                            >
                                <Crosshair className={`w-8 h-8 sm:w-12 sm:h-12 mb-2 sm:mb-3 transition-colors duration-200 ${isLaserActive ? 'text-white' : 'text-red-500'}`} />
                                <span className={`text-[10px] sm:text-xs font-bold uppercase tracking-widest transition-colors duration-200 ${isLaserActive ? 'text-white' : 'text-gray-400'}`}>
                                    {isLaserActive ? 'Gyro Active' : 'Hold to Move'}
                                </span>
                            </button>
                        </div>
                    </div>

                    {/* Dedicated Click Buttons (To prevent jitter) */}
                    <div className="w-full grid grid-cols-2 gap-3 h-20 shrink-0">
                        <button className="bg-neutral-800/80 rounded-2xl border border-white/5 flex flex-col items-center justify-center gap-1 active:bg-white/10 active:scale-95 transition-all">
                             <MousePointerClick className="w-5 h-5 sm:w-6 sm:h-6 text-blue-400" />
                             <span className="text-[10px] sm:text-xs font-bold text-gray-300">Left Click</span>
                        </button>
                        <button className="bg-neutral-800/80 rounded-2xl border border-white/5 flex flex-col items-center justify-center gap-1 active:bg-white/10 active:scale-95 transition-all">
                             <MousePointerClick className="w-5 h-5 sm:w-6 sm:h-6 text-gray-400" />
                             <span className="text-[10px] sm:text-xs font-bold text-gray-300">Right Click</span>
                        </button>
                    </div>
                </div>
            )}

            {/* Bottom Actions */}
            <div className="mt-4 flex gap-4 shrink-0">
               <button className="flex-1 py-3 sm:py-4 bg-neutral-800 rounded-2xl flex flex-col items-center gap-2 active:scale-95 transition-transform border border-white/5">
                  <Command className="w-5 h-5 sm:w-6 sm:h-6 text-white/70" />
                  <span className="text-[10px] uppercase font-bold text-gray-400">Cmd+Space</span>
               </button>
               <button className="flex-1 py-3 sm:py-4 bg-neutral-800 rounded-2xl flex flex-col items-center gap-2 active:scale-95 transition-transform border border-white/5">
                  <Grid className="w-5 h-5 sm:w-6 sm:h-6 text-white/70" />
                  <span className="text-[10px] uppercase font-bold text-gray-400">Mission Ctrl</span>
               </button>
            </div>
          </div>
        )}

        {/* TAB: MEDIA */}
        {activeTab === 'media' && (
          <div className="absolute inset-0 flex flex-col items-center justify-center p-8 space-y-10 animate-fade-in-up">
            <div className="w-64 h-64 rounded-3xl bg-gradient-to-br from-neutral-800 to-neutral-900 border border-white/10 shadow-2xl flex items-center justify-center relative overflow-hidden group">
               <Music className="w-24 h-24 text-neutral-700 group-hover:scale-110 transition-transform duration-500" />
               <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
               <div className="absolute bottom-6 left-6">
                 <div className="text-white font-bold text-xl">Unknown Track</div>
                 <div className="text-gray-400 text-sm">System Audio</div>
               </div>
            </div>

            <div className="w-full max-w-sm space-y-8">
               {/* Progress Bar */}
               <div className="w-full h-1.5 bg-neutral-800 rounded-full overflow-hidden">
                 <div className="w-1/3 h-full bg-white rounded-full"></div>
               </div>

               {/* Controls */}
               <div className="flex items-center justify-between px-4">
                  <button className="text-gray-400 hover:text-white transition-colors"><SkipBack className="w-8 h-8" /></button>
                  <button 
                    onClick={() => setIsPlaying(!isPlaying)}
                    className="w-20 h-20 rounded-full bg-white text-black flex items-center justify-center hover:scale-105 active:scale-95 transition-all shadow-[0_0_20px_rgba(255,255,255,0.3)]"
                  >
                    {isPlaying ? <Pause className="w-8 h-8 fill-current" /> : <Play className="w-8 h-8 fill-current ml-1" />}
                  </button>
                  <button className="text-gray-400 hover:text-white transition-colors"><SkipForward className="w-8 h-8" /></button>
               </div>

               {/* Volume */}
               <div className="flex items-center gap-4 bg-neutral-800/50 p-4 rounded-2xl border border-white/5">
                  <Volume2 className="w-5 h-5 text-gray-400" />
                  <input 
                    type="range" 
                    min="0" 
                    max="100" 
                    value={volume} 
                    onChange={(e) => setVolume(Number(e.target.value))}
                    className="flex-1 h-1 bg-neutral-700 rounded-lg appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:bg-white [&::-webkit-slider-thumb]:rounded-full"
                  />
                  <span className="text-xs font-mono w-8 text-right text-gray-400">{volume}%</span>
               </div>
            </div>
          </div>
        )}

        {/* TAB: SHORTCUTS/APPS */}
        {activeTab === 'apps' && (
          <div className="absolute inset-0 overflow-y-auto p-6 animate-fade-in-up">
             <h3 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4">System</h3>
             <div className="grid grid-cols-2 gap-4 mb-8">
                <button className="h-24 bg-neutral-800/50 border border-white/5 rounded-2xl flex flex-col items-center justify-center gap-2 hover:bg-neutral-700/50 active:scale-95 transition-all">
                   <Power className="w-6 h-6 text-red-500" />
                   <span className="text-sm font-medium">Sleep</span>
                </button>
                <button className="h-24 bg-neutral-800/50 border border-white/5 rounded-2xl flex flex-col items-center justify-center gap-2 hover:bg-neutral-700/50 active:scale-95 transition-all">
                   <Monitor className="w-6 h-6 text-blue-400" />
                   <span className="text-sm font-medium">Displays</span>
                </button>
                <button className="h-24 bg-neutral-800/50 border border-white/5 rounded-2xl flex flex-col items-center justify-center gap-2 hover:bg-neutral-700/50 active:scale-95 transition-all">
                   <Sun className="w-6 h-6 text-yellow-400" />
                   <span className="text-sm font-medium">Brightness</span>
                </button>
                <button className="h-24 bg-neutral-800/50 border border-white/5 rounded-2xl flex flex-col items-center justify-center gap-2 hover:bg-neutral-700/50 active:scale-95 transition-all">
                   <Grid className="w-6 h-6 text-purple-400" />
                   <span className="text-sm font-medium">Mission Control</span>
                </button>
             </div>

             <h3 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4">Apps</h3>
             <div className="grid grid-cols-4 gap-4">
                <div className="flex flex-col items-center gap-2">
                    <div className="w-16 h-16 bg-neutral-800 rounded-2xl border border-white/5 flex items-center justify-center hover:bg-neutral-700 active:scale-90 transition-all cursor-pointer">
                        <Folder className="w-8 h-8 text-blue-400" />
                    </div>
                    <span className="text-[10px] text-gray-400">Finder</span>
                </div>
                <div className="flex flex-col items-center gap-2">
                    <div className="w-16 h-16 bg-neutral-800 rounded-2xl border border-white/5 flex items-center justify-center hover:bg-neutral-700 active:scale-90 transition-all cursor-pointer">
                        <Globe className="w-8 h-8 text-green-400" />
                    </div>
                    <span className="text-[10px] text-gray-400">Chrome</span>
                </div>
                 <div className="flex flex-col items-center gap-2">
                    <div className="w-16 h-16 bg-neutral-800 rounded-2xl border border-white/5 flex items-center justify-center hover:bg-neutral-700 active:scale-90 transition-all cursor-pointer">
                        <Terminal className="w-8 h-8 text-gray-200" />
                    </div>
                    <span className="text-[10px] text-gray-400">Term</span>
                </div>
                <div className="flex flex-col items-center gap-2">
                    <div className="w-16 h-16 bg-neutral-800/30 rounded-2xl border border-dashed border-white/20 flex items-center justify-center text-white/20 hover:bg-neutral-800/50 transition-colors cursor-pointer">
                        <MoreHorizontal className="w-6 h-6" />
                    </div>
                    <span className="text-[10px] text-gray-500">More</span>
                </div>
             </div>

             <h3 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4 mt-8">Quick Launch</h3>
             <div className="grid grid-cols-2 gap-3 pb-8">
                <button className="h-14 bg-neutral-800 rounded-xl border border-white/5 flex items-center px-4 gap-3 hover:bg-neutral-700 active:scale-95 transition-all group">
                   <div className="w-8 h-8 rounded-lg bg-[#FF0000] flex items-center justify-center text-white shadow-lg shadow-red-900/20">
                      <Youtube className="w-5 h-5 fill-current" />
                   </div>
                   <span className="font-semibold text-sm text-gray-200 group-hover:text-white">YouTube</span>
                </button>

                <button className="h-14 bg-neutral-800 rounded-xl border border-white/5 flex items-center px-4 gap-3 hover:bg-neutral-700 active:scale-95 transition-all group">
                   <div className="w-8 h-8 rounded-lg bg-black border border-white/10 flex items-center justify-center text-[#E50914] shadow-lg">
                      <span className="font-black text-lg leading-none select-none">N</span>
                   </div>
                   <span className="font-semibold text-sm text-gray-200 group-hover:text-white">Netflix</span>
                </button>

                 <button className="h-14 bg-neutral-800 rounded-xl border border-white/5 flex items-center px-4 gap-3 hover:bg-neutral-700 active:scale-95 transition-all group">
                   <div className="w-8 h-8 rounded-lg bg-[#1DB954] flex items-center justify-center text-black shadow-lg shadow-green-900/20">
                      <Music className="w-5 h-5 fill-current" />
                   </div>
                   <span className="font-semibold text-sm text-gray-200 group-hover:text-white">Spotify</span>
                </button>

                 <button className="h-14 bg-neutral-800/30 rounded-xl border border-dashed border-white/20 flex items-center justify-center gap-2 hover:bg-neutral-800/50 active:scale-95 transition-all">
                   <Plus className="w-5 h-5 text-gray-500" />
                   <span className="font-medium text-sm text-gray-500">Add Shortcut</span>
                </button>
             </div>
          </div>
        )}
      </div>

      {/* Bottom Navigation */}
      <div className="px-6 pb-8 pt-4 bg-black border-t border-white/10 flex justify-between items-center z-50">
         <button 
           onClick={() => setActiveTab('remote')} 
           className={`flex flex-col items-center gap-1 transition-colors ${activeTab === 'remote' ? 'text-blue-500' : 'text-gray-500'}`}
         >
           <Tv className="w-6 h-6" />
           <span className="text-[10px] font-medium">Remote</span>
         </button>
         <button 
           onClick={() => setActiveTab('touch')} 
           className={`flex flex-col items-center gap-1 transition-colors ${activeTab === 'touch' ? 'text-blue-500' : 'text-gray-500'}`}
         >
           <MousePointer2 className="w-6 h-6" />
           <span className="text-[10px] font-medium">Touch</span>
         </button>
         <button 
           onClick={() => setActiveTab('media')} 
           className={`flex flex-col items-center gap-1 transition-colors ${activeTab === 'media' ? 'text-blue-500' : 'text-gray-500'}`}
         >
           <Music className="w-6 h-6" />
           <span className="text-[10px] font-medium">Media</span>
         </button>
         <button 
           onClick={() => setActiveTab('apps')} 
           className={`flex flex-col items-center gap-1 transition-colors ${activeTab === 'apps' ? 'text-blue-500' : 'text-gray-500'}`}
         >
           <Grid className="w-6 h-6" />
           <span className="text-[10px] font-medium">Apps</span>
         </button>
      </div>
    </div>
  );
};

export default RemoteApp;