// CodeInbox Token 存储。Dart OhosSecureStore → HUKS AES-256-GCM，密文进 preferences。
// MethodChannel: codeinbox/secure_store
//
// 协议：write(key, value) / read(key) / delete(key)
// 落盘格式：base64(12 字节 nonce || ciphertext)。密钥别名不含 token 明文。
import {
  FlutterEngine,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult
} from '@ohos/flutter_ohos';
import dataPreferences from '@ohos.data.preferences';
import { BusinessError } from '@ohos.base';
import { common } from '@kit.AbilityKit';
import { huks } from '@kit.UniversalKeystoreKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

const CHANNEL_NAME = 'codeinbox/secure_store';
const STORE_NAME = 'codeinbox_secure';
const KEY_ALIAS = 'codeinbox.aes256';
const NONCE_LEN = 12;
const AEAD_LEN = 16;

export class CodeInboxSecureStorePlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private opened: Promise<dataPreferences.Preferences> | null = null;
  private readonly b64 = new util.Base64Helper();
  private readonly encoder = new util.TextEncoder();
  private readonly decoder = new util.TextDecoder();

  getUniqueClassName(): string {
    return 'CodeInboxSecureStorePlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    const context: common.Context = binding.getApplicationContext();
    this.opened = dataPreferences.getPreferences(context, { name: STORE_NAME });
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.opened = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    const opened = this.opened;
    if (opened == null) {
      result.error('NOT_READY', 'secure store not opened yet', null);
      return;
    }
    const key = call.argument('key') as string | undefined;
    if (key == null) {
      result.error('BAD_ARGS', 'missing string argument: key', null);
      return;
    }
    opened
      .then(async (prefs: dataPreferences.Preferences) => {
        switch (call.method) {
          case 'write': {
            const value = call.argument('value') as string | undefined;
            if (value == null) {
              result.error('BAD_ARGS', 'missing string argument: value', null);
              return;
            }
            await this.ensureKey();
            const packed = await this.encrypt(this.encoder.encodeInto(value));
            await prefs.put(key, this.b64.encodeToStringSync(packed));
            await prefs.flush();
            result.success(null);
            return;
          }
          case 'read': {
            if (!prefs.hasSync(key)) {
              result.success(null);
              return;
            }
            const raw = await prefs.get(key, '') as string;
            if (raw === '') {
              result.success(null);
              return;
            }
            const plain = await this.decrypt(this.b64.decodeSync(raw));
            result.success(this.decoder.decodeToString(plain));
            return;
          }
          case 'delete':
            await prefs.delete(key);
            await prefs.flush();
            result.success(null);
            return;
          default:
            result.notImplemented();
            return;
        }
      })
      .catch((e: BusinessError | Error) => {
        const msg = (e as BusinessError).message ?? (e as Error).message;
        result.error('SECURE_FAIL', msg, null);
      });
  }

  private aesProperties(purpose: huks.HuksKeyPurpose, nonce: Uint8Array): Array<huks.HuksParam> {
    return [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: purpose },
      { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
      { tag: huks.HuksTag.HUKS_TAG_NONCE, value: nonce }
    ];
  }

  private async ensureKey(): Promise<void> {
    const empty: huks.HuksOptions = { properties: [] };
    const exists = await huks.isKeyItemExist(KEY_ALIAS, empty);
    if (exists) {
      return;
    }
    // PURPOSE 必须同时声明加解密，否则生成后无法 decrypt。
    const options: huks.HuksOptions = {
      properties: [
        { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
        { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
        {
          tag: huks.HuksTag.HUKS_TAG_PURPOSE,
          value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
        }
      ]
    };
    await huks.generateKeyItem(KEY_ALIAS, options);
  }

  private async encrypt(plain: Uint8Array): Promise<Uint8Array> {
    const nonce = (await cryptoFramework.createRandom().generateRandom(NONCE_LEN)).data;
    const props = this.aesProperties(huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT, nonce);
    const handle = await huks.initSession(KEY_ALIAS, { properties: props, inData: new Uint8Array() });
    const finished = await huks.finishSession(handle.handle, { properties: props, inData: plain });
    const cipher = finished.outData;
    if (cipher == null) {
      throw new Error('empty ciphertext');
    }
    const packed = new Uint8Array(NONCE_LEN + cipher.length);
    packed.set(nonce, 0);
    packed.set(cipher, NONCE_LEN);
    return packed;
  }

  private async decrypt(packed: Uint8Array): Promise<Uint8Array> {
    if (packed.length < NONCE_LEN + AEAD_LEN) {
      throw new Error('ciphertext too short');
    }
    const nonce = packed.slice(0, NONCE_LEN);
    const blob = packed.slice(NONCE_LEN);
    const cipher = blob.slice(0, blob.length - AEAD_LEN);
    const tag = blob.slice(blob.length - AEAD_LEN);
    const props: Array<huks.HuksParam> = [
      ...this.aesProperties(huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT, nonce),
      { tag: huks.HuksTag.HUKS_TAG_AE_TAG, value: tag }
    ];
    const handle = await huks.initSession(KEY_ALIAS, { properties: props, inData: new Uint8Array() });
    const finished = await huks.finishSession(handle.handle, { properties: props, inData: cipher });
    if (finished.outData == null) {
      throw new Error('empty plaintext');
    }
    return finished.outData;
  }

  static registerWith(engine: FlutterEngine): void {
    engine.getPlugins()?.add(new CodeInboxSecureStorePlugin());
  }
}
