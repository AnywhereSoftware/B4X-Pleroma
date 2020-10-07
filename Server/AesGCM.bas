B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private PrivateKey As Object
	Private jme As JavaObject
	Private KeyAgreement As JavaObject
	Private URLBase64Decoder As JavaObject
	Private su As StringUtils
	Private ClientPublic() As Byte
	Private Cipher As JavaObject
	
End Sub

Public Sub Initialize
	jme = Me
	URLBase64Decoder = URLBase64Decoder.InitializeStatic("java.util.Base64").RunMethod("getUrlDecoder", Null)
	PrivateKey = jme.RunMethod("loadPrivateKey", Array(su.DecodeBase64(Main.Config1.Settings.Get("private_key"))))
	KeyAgreement = KeyAgreement.InitializeStatic("javax.crypto.KeyAgreement").RunMethod("getInstance", Array("ECDH"))
	ClientPublic = su.DecodeBase64(Main.Config1.Settings.Get("client_public"))
	Cipher = Cipher.InitializeStatic("javax.crypto.Cipher").RunMethod("getInstance", Array("AES/GCM/NoPadding", "BC"))
End Sub

Public Sub DecryptMessage (dh As String, salt As String, Payload() As Byte, Auth() As Byte) As String
	
	Dim ddh() As Byte = Base64URLToBytes(dh)
	KeyAgreement.RunMethod("init", Array(PrivateKey))
	KeyAgreement.RunMethod("doPhase", Array(jme.RunMethod("loadPublicKey", Array(ddh)), True))
	Dim secret() As Byte = KeyAgreement.RunMethod("generateSecret", Null)
	Dim SecondSaltInfo() As Byte = ("Content-Encoding: auth" & Chr(0)).GetBytes("ASCII")
	Dim SecondSalt() As Byte = hkdfExpand(secret, Auth, SecondSaltInfo, 32)
	
	Dim KeyInfo() As Byte = BuildInfo("aesgcm", ClientPublic, ddh)
	Dim Key() As Byte = hkdfExpand(SecondSalt, Base64URLToBytes(salt), KeyInfo, 16)
	
	Dim nonceInfo() As Byte = BuildInfo("nonce", ClientPublic, ddh)
	Dim nonce() As Byte = hkdfExpand(SecondSalt, Base64URLToBytes(salt), nonceInfo, 12)
	Dim GCMParams As JavaObject
	GCMParams.InitializeNewInstance("javax.crypto.spec.GCMParameterSpec", Array(16 * 8, nonce))
	Dim SecretSpec As JavaObject
	SecretSpec.InitializeNewInstance("javax.crypto.spec.SecretKeySpec", Array(Key, "AES"))
	Cipher.RunMethod("init", Array(2, SecretSpec, GCMParams))
	Dim decrypted() As Byte = Cipher.RunMethod("doFinal", Array(Payload))
	Return BytesToString(decrypted, 2, decrypted.Length - 2, "UTF8")
	
End Sub

Private Sub BuildInfo(TypeS As String, ClientPublicKey() As Byte, ServerPublicKey() As Byte) As Byte()
	Dim bb As B4XBytesBuilder
	bb.Initialize
	bb.Append("Content-Encoding: ".GetBytes("ASCII"))
	bb.Append(TypeS.GetBytes("ASCII")).Append(Array As Byte(0))
	bb.Append("P-256".GetBytes("ASCII"))
	bb.Append(Array As Byte(0, 0, 65))
	bb.Append(ClientPublicKey)
	bb.Append(Array As Byte(0, 65))
	bb.Append(ServerPublicKey)
	Return bb.ToArray
End Sub

Private Sub hkdfExpand (ikm() As Byte, salt() As Byte, Info() As Byte, length As Int) As Byte()
	Dim digest As JavaObject
	digest.InitializeNewInstance("org.bouncycastle.crypto.digests.SHA256Digest", Null)
	Dim generator As JavaObject
	generator.InitializeNewInstance("org.bouncycastle.crypto.generators.HKDFBytesGenerator", Array(digest))
	Dim params As JavaObject
	params.InitializeNewInstance("org.bouncycastle.crypto.params.HKDFParameters", Array(ikm, salt, Info))
	generator.RunMethod("init", Array(params))
	Dim okm(length) As Byte
	generator.RunMethod("generateBytes", Array(okm, 0, length))
	Return okm
End Sub

Private Sub Base64URLToBytes (s As String) As Byte()
	Return URLBase64Decoder.RunMethod("decode", Array(s))
End Sub

#if Java
import org.bouncycastle.jce.ECNamedCurveTable;
import org.bouncycastle.jce.interfaces.ECPrivateKey;
import org.bouncycastle.jce.interfaces.ECPublicKey;
import org.bouncycastle.jce.spec.ECNamedCurveParameterSpec;
import org.bouncycastle.jce.spec.ECParameterSpec;
import org.bouncycastle.jce.spec.ECPrivateKeySpec;
import org.bouncycastle.jce.spec.ECPublicKeySpec;
import org.bouncycastle.math.ec.ECCurve;
import org.bouncycastle.math.ec.ECPoint;
import org.bouncycastle.util.BigIntegers;

import java.math.BigInteger;
import java.nio.ByteBuffer;
import java.security.*;
import java.security.spec.InvalidKeySpecException;
 public PrivateKey loadPrivateKey(byte[] decodedPrivateKey) throws NoSuchProviderException, NoSuchAlgorithmException, InvalidKeySpecException {
        BigInteger s = BigIntegers.fromUnsignedByteArray(decodedPrivateKey);
        ECParameterSpec parameterSpec = ECNamedCurveTable.getParameterSpec("prime256v1");
        ECPrivateKeySpec privateKeySpec = new ECPrivateKeySpec(s, parameterSpec);
        KeyFactory keyFactory = KeyFactory.getInstance("ECDH", "BC");

        return keyFactory.generatePrivate(privateKeySpec);
    }
 public PublicKey loadPublicKey(byte[] decodedPublicKey) throws NoSuchProviderException, NoSuchAlgorithmException, InvalidKeySpecException {
        KeyFactory keyFactory = KeyFactory.getInstance("ECDH", "BC");
        ECParameterSpec parameterSpec = ECNamedCurveTable.getParameterSpec("prime256v1");
        ECCurve curve = parameterSpec.getCurve();
        ECPoint point = curve.decodePoint(decodedPublicKey);
        ECPublicKeySpec pubSpec = new ECPublicKeySpec(point, parameterSpec);

        return keyFactory.generatePublic(pubSpec);
    }
#End If