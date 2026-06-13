// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title DefectReportRegistry
/// @notice Stores compact, tamper-evident defect report proofs for Ethereum testnets.
/// @dev Keep private/business data off-chain. Store hashes and compact enums only.
contract DefectReportRegistry {
    enum DefectType {
        Normal,
        Crack,
        Dent,
        Leakage,
        Other
    }

    struct DefectReport {
        bytes32 shipmentHash;
        bytes32 evidenceHash;
        DefectType defectType;
        uint16 confidenceBps;
        uint64 detectedAt;
        uint64 anchoredAt;
        address reporter;
    }

    struct DeliveryCertificate {
        bytes32 shipmentHash;
        bytes32 certificateHash;
        bytes32 recipientHash;
        bytes32 conditionHash;
        uint64 deliveredAt;
        uint64 issuedAt;
        address issuer;
    }

    address public owner;
    uint256 public reportCount;
    uint256 public certificateCount;

    mapping(address => bool) public authorizedReporters;
    mapping(bytes32 => bool) public usedEvidenceHashes;
    mapping(bytes32 => bool) public usedCertificateHashes;
    mapping(uint256 => DefectReport) private reports;
    mapping(uint256 => DeliveryCertificate) private certificates;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ReporterAuthorizationChanged(address indexed reporter, bool authorized);
    event DefectReportAnchored(
        uint256 indexed reportId,
        bytes32 indexed shipmentHash,
        bytes32 indexed evidenceHash,
        DefectType defectType,
        uint16 confidenceBps,
        uint64 detectedAt,
        address reporter
    );
    event DeliveryCertificateIssued(
        uint256 indexed certificateId,
        bytes32 indexed shipmentHash,
        bytes32 indexed certificateHash,
        bytes32 recipientHash,
        bytes32 conditionHash,
        uint64 deliveredAt,
        address issuer
    );

    error NotOwner();
    error NotAuthorizedReporter();
    error InvalidOwner();
    error InvalidHash();
    error InvalidConfidence();
    error DuplicateEvidence();
    error DuplicateCertificate();
    error ReportNotFound();
    error CertificateNotFound();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyReporter() {
        if (!authorizedReporters[msg.sender]) revert NotAuthorizedReporter();
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedReporters[msg.sender] = true;
        emit OwnershipTransferred(address(0), msg.sender);
        emit ReporterAuthorizationChanged(msg.sender, true);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidOwner();
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function setReporter(address reporter, bool authorized) external onlyOwner {
        authorizedReporters[reporter] = authorized;
        emit ReporterAuthorizationChanged(reporter, authorized);
    }

    function anchorReport(
        bytes32 shipmentHash,
        bytes32 evidenceHash,
        DefectType defectType,
        uint16 confidenceBps,
        uint64 detectedAt
    ) external onlyReporter returns (uint256 reportId) {
        if (shipmentHash == bytes32(0) || evidenceHash == bytes32(0)) revert InvalidHash();
        if (confidenceBps > 10000) revert InvalidConfidence();
        if (usedEvidenceHashes[evidenceHash]) revert DuplicateEvidence();

        reportId = ++reportCount;
        usedEvidenceHashes[evidenceHash] = true;

        reports[reportId] = DefectReport({
            shipmentHash: shipmentHash,
            evidenceHash: evidenceHash,
            defectType: defectType,
            confidenceBps: confidenceBps,
            detectedAt: detectedAt,
            anchoredAt: uint64(block.timestamp),
            reporter: msg.sender
        });

        emit DefectReportAnchored(
            reportId,
            shipmentHash,
            evidenceHash,
            defectType,
            confidenceBps,
            detectedAt,
            msg.sender
        );
    }

    function getReport(uint256 reportId) external view returns (DefectReport memory report) {
        if (reportId == 0 || reportId > reportCount) revert ReportNotFound();
        return reports[reportId];
    }

    function verifyEvidence(bytes32 evidenceHash) external view returns (bool) {
        return usedEvidenceHashes[evidenceHash];
    }

    function issueDeliveryCertificate(
        bytes32 shipmentHash,
        bytes32 certificateHash,
        bytes32 recipientHash,
        bytes32 conditionHash,
        uint64 deliveredAt
    ) external onlyReporter returns (uint256 certificateId) {
        if (
            shipmentHash == bytes32(0) ||
            certificateHash == bytes32(0) ||
            recipientHash == bytes32(0) ||
            conditionHash == bytes32(0)
        ) revert InvalidHash();
        if (usedCertificateHashes[certificateHash]) revert DuplicateCertificate();

        certificateId = ++certificateCount;
        usedCertificateHashes[certificateHash] = true;

        certificates[certificateId] = DeliveryCertificate({
            shipmentHash: shipmentHash,
            certificateHash: certificateHash,
            recipientHash: recipientHash,
            conditionHash: conditionHash,
            deliveredAt: deliveredAt,
            issuedAt: uint64(block.timestamp),
            issuer: msg.sender
        });

        emit DeliveryCertificateIssued(
            certificateId,
            shipmentHash,
            certificateHash,
            recipientHash,
            conditionHash,
            deliveredAt,
            msg.sender
        );
    }

    function getCertificate(uint256 certificateId) external view returns (DeliveryCertificate memory certificate) {
        if (certificateId == 0 || certificateId > certificateCount) revert CertificateNotFound();
        return certificates[certificateId];
    }

    function verifyCertificate(bytes32 certificateHash) external view returns (bool) {
        return usedCertificateHashes[certificateHash];
    }
}
