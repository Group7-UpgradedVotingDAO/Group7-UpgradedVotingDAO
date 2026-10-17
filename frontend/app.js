const SEPOLIA_CHAIN_ID = "0xaa36a7";

// IMPORTANT: Insert your VERIFIED VotingDAO deployment address here.
const CONTRACT_ADDRESS = "";

const ABI = [
    "function joinDAO() external",
    "function createProposal(string _description, uint256 _duration) external",
    "function vote(uint256 _proposalId, bool _support) external",
    "function proposalCount() view returns (uint256)",
    "function memberCount() view returns (uint256)",
    "function members(address) view returns (bool isMember, uint256 votingPower)",
    "function proposals(uint256) view returns (uint256 id, string description, uint256 yesVotes, uint256 noVotes, uint256 deadline, bool executed)",
    "function hasVoted(uint256,address) view returns (bool)",
    "function MINIMUM_QUORUM() view returns (uint256)"
];

const $ = (id) => document.getElementById(id);

const connectButton = $("connect-btn");
const toast = $("toast");
let provider;
let signer;
let contract;
let account;

function showToast(message) {
    if (toast) {
        toast.textContent = message;
        toast.classList.add("show");
        setTimeout(() => toast.classList.remove("show"), 4000);
    } else {
        alert(message);
    }
}

function shortAddress(address) {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

function requireConnection() {
    if (!contract || !account) {
        throw new Error("Connect MetaMask to Sepolia first.");
    }
}

async function connectWallet() {
    try {
        if (!window.ethereum) {
            throw new Error("Install or open MetaMask first.");
        }

        await window.ethereum.request({ method: "eth_requestAccounts" });

        provider = new ethers.BrowserProvider(window.ethereum);
        signer = await provider.getSigner();
        account = await signer.getAddress();

        const network = await provider.getNetwork();

        if (network.chainId !== 11155111n) {
            contract = null;
            showToast("Switch MetaMask to Sepolia and connect again.");
            return;
        }

        if (!/^0x[a-fA-F0-9]{40}$/.test(CONTRACT_ADDRESS)) {
            contract = null;
            connectButton.textContent = shortAddress(account);
            showToast("Wallet connected. The verified DAO contract address is still missing.");
            return;
        }

        const code = await provider.getCode(CONTRACT_ADDRESS);
        if (code === "0x") {
            contract = null;
            showToast("No contract exists at that address on Sepolia.");
            return;
        }

        contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
        connectButton.textContent = shortAddress(account);

        await refreshDashboard();
        showToast("Wallet connected to Governance Hub!");
    } catch (error) {
        console.error(error);
        showToast(error.shortMessage || error.message || "Wallet connection failed.");
    }
}

async function sendTransaction(action) {
    requireConnection();
    showToast("Please confirm the transaction in MetaMask.");

    const tx = await action();
    showToast("Transaction submitted. Waiting for confirmation...");

    await tx.wait();
    await refreshDashboard();
    showToast("Transaction confirmed on Sepolia!");
}

function addJoinButton() {
    if ($("join-dao-btn") || !connectButton) return;

    const button = document.createElement("button");
    button.id = "join-dao-btn";
    button.type = "button";
    button.className = "primary-button";
    button.textContent = "Join DAO";
    button.style.marginLeft = "10px";

    connectButton.insertAdjacentElement("afterend", button);

    button.addEventListener("click", async () => {
        try {
            requireConnection();

            const member = await contract.members(account);
            if (member.isMember) {
                showToast("Your wallet is already a DAO member.");
                return;
            }

            await sendTransaction(() => contract.joinDAO());
        } catch (error) {
            showToast(error.shortMessage || error.reason || error.message);
        }
    });
}

async function refreshDashboard() {
    requireConnection();

    const [members, count] = await Promise.all([
        contract.memberCount(),
        contract.proposalCount()
    ]);

    $("member-count").textContent = members.toString();
    $("proposal-count").textContent = count.toString();

    const list = $("proposal-list");
    list.innerHTML = "";

    if (count === 0n) {
        list.innerHTML = `
            <div class="empty-state">
                <h3>No proposals yet</h3>
                <p>Join the DAO and create the first proposal.</p>
            </div>`;
        return;
    }

    for (let i = count; i >= 1n; i--) {
        const p = await contract.proposals(i);
        const hasVoted = await contract.hasVoted(i, account);
        const ended = BigInt(Math.floor(Date.now() / 1000)) >= p.deadline;
const card = document.createElement("article");
        card.className = "proposal-card";

        const deadlineText = new Date(
            Number(p.deadline) * 1000
        ).toLocaleString();

        const ended =
            BigInt(Math.floor(Date.now() / 1000)) >= p.deadline;

        const yesVotes = Number(p.yesVotes);
        const noVotes = Number(p.noVotes);
        const totalVotes = yesVotes + noVotes;
        const yesPercentage = totalVotes > 0
            ? (yesVotes / totalVotes) * 100
            : 0;

        card.innerHTML = `
            <div class="proposal-card-top">
                <div>
                    <p class="proposal-id">PROPOSAL #${p.id}</p>
                    <h3 class="proposal-description"></h3>
                </div>
                <span class="proposal-status ${ended ? "closed" : ""}">
                    ${p.executed ? "Executed" : ended ? "Voting ended" : "Voting open"}
                </span>
            </div>

            <div class="vote-summary">
                <span>Yes: ${yesVotes}</span>
                <span>No: ${noVotes}</span>
            </div>

            <div class="vote-bar">
                <div class="vote-bar-yes" style="width: ${yesPercentage}%"></div>
            </div>

            <div class="proposal-actions">
                <button type="button" class="action-button yes vote-yes">Vote Yes</button>
                <button type="button" class="action-button no vote-no">Vote No</button>
            </div>

            <p class="proposal-deadline">Deadline: ${deadlineText}</p>
        `;

        card.querySelector(".proposal-description").textContent =
            p.description;

        const yesButton = card.querySelector(".vote-yes");
        const noButton = card.querySelector(".vote-no");

        if (ended || hasVoted || p.executed) {
            yesButton.disabled = true;
            noButton.disabled = true;
        }

        yesButton.addEventListener("click", () => castVote(i, true));
        noButton.addEventListener("click", () => castVote(i, false));

        list.appendChild(card);

        card.className = "proposal-card";



        const deadlineText = new Date(
            Number(p.deadline) * 1000
        ).toLocaleString();

        card.innerHTML = `
            <p>PROPOSAL #${p.id}</p>
            <h3 class="proposal-description"></h3>
            <p>Yes votes: ${p.yesVotes} · No votes: ${p.noVotes}</p>
            <p>Deadline: ${deadlineText}</p>
            <p>Status: ${p.executed ? "Executed" : ended ? "Voting ended" : "Voting open"}</p>
            <div class="vote-actions">
                <button type="button" class="primary-button vote-yes">Vote Yes</button>
                <button type="button" class="primary-button vote-no">Vote No</button>
            </div>`;

        card.querySelector(".proposal-description").textContent = p.description;

        const yesButton = card.querySelector(".vote-yes");
        const noButton = card.querySelector(".vote-no");

        if (ended || hasVoted) {
            yesButton.disabled = true;
            noButton.disabled = true;
        }

        yesButton.addEventListener("click", () => castVote(i, true));
        noButton.addEventListener("click", () => castVote(i, false));

        list.appendChild(card);
    }
}

async function castVote(proposalId, support) {
    try {
        const member = await contract.members(account);
        if (!member.isMember) {
            throw new Error("Join the DAO before voting.");
        }

        await sendTransaction(() => contract.vote(proposalId, support));
    } catch (error) {
        showToast(error.shortMessage || error.reason || error.message);
    }
}

const proposalForm = $("proposal-form");

if (proposalForm) {
    proposalForm.addEventListener("submit", async (event) => {
        event.preventDefault();

        try {
            requireConnection();

            const description = $("proposal-description").value.trim();
            const duration = $("proposal-duration").value;

            if (!description) {
                throw new Error("Enter a proposal description.");
            }

            const member = await contract.members(account);
            if (!member.isMember) {
                throw new Error("Join the DAO before creating a proposal.");
            }

            await sendTransaction(() =>
                contract.createProposal(description, BigInt(duration))
            );

            proposalForm.reset();
        } catch (error) {
            showToast(error.shortMessage || error.reason || error.message);
        }
    });
}

if (connectButton) {
    connectButton.addEventListener("click", connectWallet);
}

addJoinButton();

if (window.ethereum) {
    window.ethereum.on("accountsChanged", () => window.location.reload());
    window.ethereum.on("chainChanged", () => window.location.reload());
}

console.log("Governance Hub loaded.");